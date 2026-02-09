import Foundation
import Testing

@testable import Core

@Test func workflowProgressRequiresInputBeforeAnythingElse() {
  let document = PlanDocument(title: "Plan", rawInput: "")

  let progress = WorkflowGuidanceEngine.progress(document: document)

  #expect(progress.recommendedStage == .inputMaterial)
  #expect(progress.completedStageCount == 0)
  #expect(progress.hasInputMaterial == false)
  #expect(progress.hasOutline == false)
  #expect(progress.hasArtifacts == false)
  #expect(progress.hasExecutableTodos == false)
}

@Test func workflowProgressMovesToGeneratePlanAfterInputReady() {
  let document = PlanDocument(title: "Plan", rawInput: "Learn Swift")

  let progress = WorkflowGuidanceEngine.progress(document: document)

  #expect(progress.recommendedStage == .generatePlan)
  #expect(progress.completedStageCount == 1)
  #expect(progress.hasInputMaterial)
  #expect(progress.hasOutline == false)
}

@Test func workflowProgressMovesToOrganizeArtifactsAfterOutlineReady() {
  let document = PlanDocument(title: "Plan", rawInput: "Learn Swift")
  document.outline = PlanOutline(planJSON: "{}", planMarkdown: "# Plan")

  let progress = WorkflowGuidanceEngine.progress(document: document)

  #expect(progress.recommendedStage == .organizeArtifacts)
  #expect(progress.completedStageCount == 2)
  #expect(progress.hasOutline)
  #expect(progress.hasArtifacts == false)
}

@Test func workflowProgressMovesToTodayExecutionWhenExecutableTodoExists() {
  let document = PlanDocument(title: "Plan", rawInput: "Learn Swift")
  document.outline = PlanOutline(planJSON: "{}", planMarkdown: "# Plan")

  let todo = TodoItem(
    title: "Do exercise",
    detail: "",
    statusRaw: TodoStatus.todo.rawValue,
    priorityRaw: TodoPriority.medium.rawValue
  )
  todo.document = document
  document.todos.append(todo)

  let progress = WorkflowGuidanceEngine.progress(document: document)

  #expect(progress.recommendedStage == .todayExecution)
  #expect(progress.completedStageCount == 4)
  #expect(progress.hasArtifacts)
  #expect(progress.hasExecutableTodos)
}

@Test func executionQualityIssuesDetectNoTodos() {
  let issues = WorkflowGuidanceEngine.executionQualityIssues(todos: [])

  #expect(issues.count == 1)
  #expect(issues[0].kind == .noTodos)
  #expect(issues[0].repairAction == .openGeneratePlan)
}

@Test func executionQualityIssuesDetectHighPriorityMissingSchedule() {
  let highNoSchedule = TodoItem(
    title: "Critical",
    detail: "",
    statusRaw: TodoStatus.todo.rawValue,
    priorityRaw: TodoPriority.high.rawValue
  )
  let mediumScheduled = TodoItem(
    title: "Normal",
    detail: "",
    statusRaw: TodoStatus.todo.rawValue,
    priorityRaw: TodoPriority.medium.rawValue,
    scheduledAt: .now
  )

  let issues = WorkflowGuidanceEngine.executionQualityIssues(todos: [highNoSchedule, mediumScheduled])

  #expect(issues.contains(where: { $0.kind == .highPriorityMissingSchedule }))
}

@Test func executionQualityIssuesDetectBlockedMissingDetail() {
  let blockedEmpty = TodoItem(
    title: "Blocked",
    detail: "",
    statusRaw: TodoStatus.blocked.rawValue,
    priorityRaw: TodoPriority.medium.rawValue
  )

  let issues = WorkflowGuidanceEngine.executionQualityIssues(todos: [blockedEmpty])

  #expect(issues.contains(where: { $0.kind == .blockedMissingDetail }))
}

@Test func executionQualityIssuesDetectTooManyUnscheduled() {
  let todos = [
    TodoItem(
      title: "A",
      detail: "",
      statusRaw: TodoStatus.todo.rawValue,
      priorityRaw: TodoPriority.medium.rawValue
    ),
    TodoItem(
      title: "B",
      detail: "",
      statusRaw: TodoStatus.todo.rawValue,
      priorityRaw: TodoPriority.medium.rawValue
    ),
    TodoItem(
      title: "C",
      detail: "",
      statusRaw: TodoStatus.todo.rawValue,
      priorityRaw: TodoPriority.medium.rawValue
    ),
    TodoItem(
      title: "D",
      detail: "",
      statusRaw: TodoStatus.todo.rawValue,
      priorityRaw: TodoPriority.medium.rawValue,
      dueAt: .now
    )
  ]

  let issues = WorkflowGuidanceEngine.executionQualityIssues(todos: todos)

  #expect(issues.contains(where: { $0.kind == .tooManyUnscheduled }))
}

@Test func executionQualityIssuesRemainCleanWhenTodosHealthy() {
  let todos = [
    TodoItem(
      title: "High Scheduled",
      detail: "Ready",
      statusRaw: TodoStatus.todo.rawValue,
      priorityRaw: TodoPriority.high.rawValue,
      dueAt: .now
    ),
    TodoItem(
      title: "Blocked With Reason",
      detail: "Waiting API",
      statusRaw: TodoStatus.blocked.rawValue,
      priorityRaw: TodoPriority.medium.rawValue
    ),
    TodoItem(
      title: "In Progress",
      detail: "",
      statusRaw: TodoStatus.doing.rawValue,
      priorityRaw: TodoPriority.medium.rawValue,
      scheduledAt: .now
    )
  ]

  let issues = WorkflowGuidanceEngine.executionQualityIssues(todos: todos)

  #expect(issues.isEmpty)
}
