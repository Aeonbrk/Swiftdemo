import Foundation

public enum WorkflowStage: String, CaseIterable, Sendable {
  case inputMaterial
  case generatePlan
  case organizeArtifacts
  case todayExecution
}

public struct WorkflowProgressSnapshot: Equatable, Sendable {
  public let recommendedStage: WorkflowStage
  public let completedStageCount: Int
  public let hasInputMaterial: Bool
  public let hasOutline: Bool
  public let hasArtifacts: Bool
  public let hasExecutableTodos: Bool

  public init(
    recommendedStage: WorkflowStage,
    completedStageCount: Int,
    hasInputMaterial: Bool,
    hasOutline: Bool,
    hasArtifacts: Bool,
    hasExecutableTodos: Bool
  ) {
    self.recommendedStage = recommendedStage
    self.completedStageCount = completedStageCount
    self.hasInputMaterial = hasInputMaterial
    self.hasOutline = hasOutline
    self.hasArtifacts = hasArtifacts
    self.hasExecutableTodos = hasExecutableTodos
  }
}

public enum WorkflowQualityIssueKind: String, Sendable {
  case noTodos
  case highPriorityMissingSchedule
  case blockedMissingDetail
  case tooManyUnscheduled
}

public enum WorkflowQualityRepairAction: String, Sendable {
  case openGeneratePlan
  case scheduleHighPriorityTodos
  case completeBlockedTodoDetail
  case scheduleUnplannedTodos
}

public struct WorkflowQualityIssue: Equatable, Sendable {
  public let kind: WorkflowQualityIssueKind
  public let title: String
  public let detail: String
  public let affectedCount: Int
  public let repairAction: WorkflowQualityRepairAction

  public init(
    kind: WorkflowQualityIssueKind,
    title: String,
    detail: String,
    affectedCount: Int,
    repairAction: WorkflowQualityRepairAction
  ) {
    self.kind = kind
    self.title = title
    self.detail = detail
    self.affectedCount = affectedCount
    self.repairAction = repairAction
  }
}

public enum WorkflowGuidanceEngine {
  private static let unscheduledThresholdCount = 3
  private static let unscheduledThresholdRatio = 0.6

  public static func progress(document: PlanDocument) -> WorkflowProgressSnapshot {
    let hasInputMaterial = document.rawInput
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .isEmpty == false

    let hasOutline = hasOutlineContent(document)
    let hasArtifacts = document.flashcards.isEmpty == false || document.todos.isEmpty == false
    let hasExecutableTodos = document.todos.contains(where: isExecutableTodo)

    let recommendedStage: WorkflowStage
    if hasInputMaterial == false {
      recommendedStage = .inputMaterial
    } else if hasOutline == false {
      recommendedStage = .generatePlan
    } else if hasArtifacts == false {
      recommendedStage = .organizeArtifacts
    } else if hasExecutableTodos == false {
      recommendedStage = .organizeArtifacts
    } else {
      recommendedStage = .todayExecution
    }

    let completedStageCount = [
      hasInputMaterial,
      hasOutline,
      hasArtifacts,
      hasExecutableTodos
    ]
    .filter { $0 }
    .count

    return WorkflowProgressSnapshot(
      recommendedStage: recommendedStage,
      completedStageCount: completedStageCount,
      hasInputMaterial: hasInputMaterial,
      hasOutline: hasOutline,
      hasArtifacts: hasArtifacts,
      hasExecutableTodos: hasExecutableTodos
    )
  }

  public static func executionQualityIssues(
    todos: [TodoItem],
    now: Date = .now
  ) -> [WorkflowQualityIssue] {
    if todos.isEmpty {
      return [
        WorkflowQualityIssue(
          kind: .noTodos,
          title: "暂无可执行任务",
          detail: "先生成或补充任务，再开始今日执行。",
          affectedCount: 0,
          repairAction: .openGeneratePlan
        )
      ]
    }

    var issues: [WorkflowQualityIssue] = []
    if let issue = highPriorityMissingScheduleIssue(todos: todos) {
      issues.append(issue)
    }
    if let issue = blockedMissingDetailIssue(todos: todos) {
      issues.append(issue)
    }
    if let issue = unscheduledPlanningIssue(todos: todos, now: now) {
      issues.append(issue)
    }

    return issues
  }

  private static func highPriorityMissingScheduleIssue(todos: [TodoItem]) -> WorkflowQualityIssue? {
    let highPriorityMissingSchedule = todos.filter {
      $0.status != .done
        && $0.priority == .high
        && $0.dueAt == nil
        && $0.scheduledAt == nil
    }
    guard highPriorityMissingSchedule.isEmpty == false else { return nil }
    return WorkflowQualityIssue(
      kind: .highPriorityMissingSchedule,
      title: "高优先任务缺少时间安排",
      detail: "为高优先任务补充计划时间或截止时间，避免执行顺序混乱。",
      affectedCount: highPriorityMissingSchedule.count,
      repairAction: .scheduleHighPriorityTodos
    )
  }

  private static func blockedMissingDetailIssue(todos: [TodoItem]) -> WorkflowQualityIssue? {
    let blockedMissingDetail = todos.filter {
      $0.status == .blocked
        && $0.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    guard blockedMissingDetail.isEmpty == false else { return nil }
    return WorkflowQualityIssue(
      kind: .blockedMissingDetail,
      title: "阻塞任务缺少原因说明",
      detail: "补充阻塞原因与解除条件，方便后续恢复执行。",
      affectedCount: blockedMissingDetail.count,
      repairAction: .completeBlockedTodoDetail
    )
  }

  private static func unscheduledPlanningIssue(
    todos: [TodoItem],
    now: Date
  ) -> WorkflowQualityIssue? {
    _ = now
    let activeTodos = todos.filter { $0.status != .done }
    let unscheduledActiveTodos = activeTodos.filter {
      $0.scheduledAt == nil && $0.dueAt == nil
    }
    guard activeTodos.count >= unscheduledThresholdCount else { return nil }
    let ratio = Double(unscheduledActiveTodos.count) / Double(activeTodos.count)
    guard ratio >= unscheduledThresholdRatio else { return nil }
    return WorkflowQualityIssue(
      kind: .tooManyUnscheduled,
      title: "任务时间规划不足",
      detail: "当前多数任务未安排时间，建议先给近期任务加时间窗口。",
      affectedCount: unscheduledActiveTodos.count,
      repairAction: .scheduleUnplannedTodos
    )
  }

  private static func hasOutlineContent(_ document: PlanDocument) -> Bool {
    guard let outline = document.outline else { return false }
    return outline.planJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
      || outline.planMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }

  private static func isExecutableTodo(_ todo: TodoItem) -> Bool {
    todo.status != .done && todo.status != .blocked && todo.completedAt == nil
  }
}
