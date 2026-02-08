import Core
import Foundation
import SwiftData
import SwiftUI

enum ExecutionDashboardFilter: String, CaseIterable, Identifiable {
  case today
  case overdue
  case done
  case blocked

  var id: String { rawValue }

  var title: String {
    switch self {
    case .today:
      "今日"
    case .overdue:
      "逾期"
    case .done:
      "已完成"
    case .blocked:
      "阻塞"
    }
  }
}

struct PendingSyncReview: Identifiable {
  let id: UUID
  let todoID: UUID
  let remoteRecord: ExternalTaskRecord
  let createdAt: Date
  let reason: String

  init(todoID: UUID, remoteRecord: ExternalTaskRecord, reason: String, createdAt: Date = .now) {
    self.id = todoID
    self.todoID = todoID
    self.remoteRecord = remoteRecord
    self.createdAt = createdAt
    self.reason = reason
  }
}

extension PlanInputView {
  var executionTab: some View {
    AppRouteScaffold {
      executionToolbar

      if executionSuggestionRows.isEmpty == false {
        executionRecommendationPanel
      }

      if pendingSyncReviews.isEmpty == false {
        executionPendingReviewPanel
      }

      if recentAutomationAudits.isEmpty == false {
        executionAutomationAuditPanel
      }

      if executionFilteredTodos.isEmpty {
        AppPanelCard {
          AppEmptyStatePanel(
            title: "当前筛选下无任务",
            systemImage: "bolt.slash",
            description: "切换筛选条件，或先在任务页创建待办。"
          )
        }
      } else {
        AppPanelList {
          ForEach(executionFilteredTodos, id: \.id) { todo in
            executionRow(todo)
              .padding(.horizontal, UIStyle.panelInnerPadding)
              .padding(.vertical, UIStyle.listRowVerticalPadding)
              .appRowGlass()
              .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
          }
        }
      }
    }
  }

  private var executionToolbar: some View {
    AppActionBar {
      HStack(spacing: UIStyle.compactSpacing) {
        Picker("筛选", selection: $executionFilter) {
          ForEach(ExecutionDashboardFilter.allCases, id: \.self) { filter in
            Text(filter.title).tag(filter)
          }
        }
        .pickerStyle(.segmented)

        Spacer(minLength: UIStyle.compactSpacing)

        if executionSuggestionRows.isEmpty == false {
          Text("建议 \(executionSuggestionRows.count) 项")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Menu {
          Picker("冲突策略", selection: syncOwnershipPolicyBinding) {
            ForEach(SyncOwnershipPolicy.allCases, id: \.self) { policy in
              Text(syncOwnershipPolicyTitle(policy)).tag(policy)
            }
          }
        } label: {
          Label(syncOwnershipPolicyTitle(syncOwnershipPolicy), systemImage: "arrow.triangle.2.circlepath")
        }
        .appSecondaryActionButtonStyle()

        Menu {
          Picker("自动化权限", selection: automationPermissionPolicyBinding) {
            ForEach(AutomationPermissionPolicy.allCases, id: \.self) { policy in
              Text(automationPermissionPolicyTitle(policy)).tag(policy)
            }
          }
        } label: {
          Label(automationPermissionPolicyTitle(automationPermissionPolicy), systemImage: "hand.raised")
        }
        .appSecondaryActionButtonStyle()

        Text("共 \(executionFilteredTodos.count) 项")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var executionRecommendations: [TodoRecommendation] {
    ExecutionSuggestionEngine.recommendations(
      for: document.todos,
      now: .now,
      limit: max(3, document.todos.count)
    )
  }

  private var pendingExecutionRecommendations: [TodoRecommendation] {
    let activeIDs = Set(document.todos.map(\.id))
    return executionRecommendations.filter {
      activeIDs.contains($0.todoID) && handledRecommendationTodoIDs.contains($0.todoID) == false
    }
  }

  private var executionSuggestionRows: [(recommendation: TodoRecommendation, todo: TodoItem)] {
    pendingExecutionRecommendations
      .prefix(3)
      .compactMap { recommendation in
        document.todos.first(where: { $0.id == recommendation.todoID }).map {
          (recommendation: recommendation, todo: $0)
        }
      }
  }

  private var executionScoreByTodoID: [UUID: Int] {
    Dictionary(uniqueKeysWithValues: executionRecommendations.map { ($0.todoID, $0.score) })
  }

  private var executionRecommendationPanel: some View {
    AppPanelCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("建议优先处理")
          .font(.headline)

        ForEach(executionSuggestionRows, id: \.todo.id) { row in
          HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
              Text(row.todo.title.isEmpty ? "（无标题）" : row.todo.title)
                .font(.subheadline.weight(.semibold))
              Text("Score \(row.recommendation.score) · \(row.recommendation.reasons.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }

            Spacer(minLength: UIStyle.compactSpacing)

            Button("采用") {
              acceptRecommendation(for: row.todo)
            }
            .appPrimaryActionButtonStyle()

            Button("忽略") {
              dismissRecommendation(for: row.todo)
            }
            .appSecondaryActionButtonStyle()
          }
        }
      }
    }
  }

  private var pendingSyncReviews: [PendingSyncReview] {
    pendingSyncReviewsByTodoID.values.sorted(by: { $0.createdAt > $1.createdAt })
  }

  private var recentAutomationAudits: [AutomationAuditEntry] {
    document.automationAudits.sorted(by: { $0.createdAt > $1.createdAt })
  }

  private var executionPendingReviewPanel: some View {
    AppPanelCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("待审核自动化变更")
          .font(.headline)

        ForEach(pendingSyncReviews, id: \.id) { review in
          VStack(alignment: .leading, spacing: 8) {
            Text(pendingReviewTitle(review))
              .font(.subheadline.weight(.semibold))
            Text(review.reason)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)

            HStack(spacing: 8) {
              Button("保留本地") {
                keepLocalForPendingReview(review)
              }
              .appSecondaryActionButtonStyle()

              Button("应用远端") {
                applyRemoteForPendingReview(review)
              }
              .appPrimaryActionButtonStyle()

              Button("打开任务") {
                navigateToPendingReviewTodo(review)
              }
              .appSecondaryActionButtonStyle()
            }
          }
          .padding(8)
          .appChipGlass()
        }
      }
    }
  }

  private var executionAutomationAuditPanel: some View {
    AppPanelCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("自动化审计")
          .font(.headline)

        ForEach(Array(recentAutomationAudits.prefix(5)), id: \.id) { audit in
          HStack(alignment: .top, spacing: 8) {
            Text(automationAuditStatusTitle(audit.status))
              .font(.caption2)
              .foregroundStyle(.secondary)
              .frame(minWidth: 42, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
              Text(audit.summary)
                .font(.caption)
                .lineLimit(2)
              Text(audit.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }

  private var executionFilteredTodos: [TodoItem] {
    let scoreByTodoID = executionScoreByTodoID
    let todos = document.todos.filter(matchesExecutionFilter)
    switch executionFilter {
    case .done:
      return todos.sorted(by: { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) })
    default:
      return todos.sorted {
        let lhsScore = scoreByTodoID[$0.id] ?? Int.min
        let rhsScore = scoreByTodoID[$1.id] ?? Int.min
        if lhsScore != rhsScore {
          return lhsScore > rhsScore
        }
        return executionSortDate(for: $0) < executionSortDate(for: $1)
      }
    }
  }

  private func matchesExecutionFilter(_ todo: TodoItem) -> Bool {
    let startOfToday = Calendar.current.startOfDay(for: .now)
    let isDone = todo.status == .done || todo.completedAt != nil
    let isBlocked = todo.status == .blocked
    let isOverdue = todo.dueAt.map { $0 < startOfToday } ?? false
    let isTodayScheduled = [todo.scheduledAt, todo.dueAt]
      .compactMap { $0 }
      .contains(where: { Calendar.current.isDateInToday($0) })
    let hasNoSchedule = todo.scheduledAt == nil && todo.dueAt == nil

    switch executionFilter {
    case .today:
      return isDone == false && isBlocked == false && isOverdue == false
        && (isTodayScheduled || hasNoSchedule)
    case .overdue:
      return isDone == false && isOverdue
    case .done:
      return isDone
    case .blocked:
      return isBlocked && isDone == false
    }
  }

  private func executionSortDate(for todo: TodoItem) -> Date {
    todo.dueAt ?? todo.scheduledAt ?? todo.createdAt
  }

  private func executionRow(_ todo: TodoItem) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      executionRowHeader(for: todo)
      executionRowDetail(for: todo)
      executionRowMeta(for: todo)
      executionRowEvidence(for: todo)
      executionRowActions(for: todo)
    }
  }

  private func executionRowHeader(for todo: TodoItem) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(todo.title.isEmpty ? "（无标题）" : todo.title)
        .font(.body.weight(.medium))
        .lineLimit(2)

      Spacer(minLength: UIStyle.compactSpacing)

      Text(todo.status.rawValue)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private func executionRowDetail(for todo: TodoItem) -> some View {
    Group {
      if todo.detail.isEmpty == false {
        Text(todo.detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
  }

  private func executionRowMeta(for todo: TodoItem) -> some View {
    HStack(spacing: 8) {
      Text("P:\(todo.priority.rawValue)")
        .font(.caption2)
        .foregroundStyle(.secondary)

      if let score = executionScoreByTodoID[todo.id] {
        Text("Score \(score)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      if let dueAt = todo.dueAt {
        Text("截止 \(dueAt.formatted(date: .abbreviated, time: .shortened))")
          .font(.caption2)
          .foregroundStyle(.secondary)
      } else if let scheduledAt = todo.scheduledAt {
        Text("计划 \(scheduledAt.formatted(date: .abbreviated, time: .shortened))")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func executionRowActions(for todo: TodoItem) -> some View {
    HStack(spacing: 8) {
      Button("待办") {
        setTodoStatus(todo, to: .todo)
      }
      .appSecondaryActionButtonStyle()
      .disabled(todo.status == .todo)

      Button("开始") {
        setTodoStatus(todo, to: .doing)
      }
      .appSecondaryActionButtonStyle()
      .disabled(todo.status == .doing)

      Button("阻塞") {
        setTodoStatus(todo, to: .blocked)
      }
      .appSecondaryActionButtonStyle()
      .disabled(todo.status == .blocked)

      Button(todo.status == .done ? "重开" : "完成") {
        setTodoStatus(todo, to: todo.status == .done ? .todo : .done)
      }
      .appPrimaryActionButtonStyle()

      Button(syncActionButtonTitle) {
        syncTodoWithMockRemote(todo)
      }
      .appSecondaryActionButtonStyle()
    }
  }

  private func executionRowEvidence(for todo: TodoItem) -> some View {
    let linkedClaims = executionLinkedClaims(for: todo)
    let linkedCitations = executionLinkedCitations(for: todo)
    let missingEvidenceCount = executionMissingEvidenceCount(for: todo)

    return Group {
      if linkedClaims.isEmpty == false || linkedCitations.isEmpty == false || missingEvidenceCount > 0 {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 8) {
            Label(
              "证据 主张\(linkedClaims.count) / 引用\(linkedCitations.count)",
              systemImage: "link.badge.plus"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer(minLength: UIStyle.compactSpacing)

            Button("编辑关联") {
              navigateToTodoEvidenceEditor(todo)
            }
            .appSecondaryActionButtonStyle()
          }

          if linkedClaims.isEmpty == false {
            VStack(alignment: .leading, spacing: 4) {
              ForEach(Array(linkedClaims.prefix(2)), id: \.id) { claim in
                Text("• \(claim.text.isEmpty ? "（空主张）" : claim.text)")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                  .lineLimit(2)
              }

              if linkedClaims.count > 2 {
                Text("… 还有 \(linkedClaims.count - 2) 条主张")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
            }
          }

          if linkedCitations.isEmpty == false {
            VStack(alignment: .leading, spacing: 4) {
              ForEach(Array(linkedCitations.prefix(2)), id: \.id) { citation in
                if let url = URL(string: citation.url), citation.url.isEmpty == false {
                  Link(destination: url) {
                    Label(executionCitationTitle(citation), systemImage: "link")
                      .font(.caption2)
                      .lineLimit(1)
                  }
                } else {
                  Text("• \(executionCitationTitle(citation))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
              }

              if linkedCitations.count > 2 {
                Text("… 还有 \(linkedCitations.count - 2) 条引用")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
            }
          }

          HStack(spacing: 8) {
            if linkedCitations.isEmpty == false {
              Button("查看引用页") {
                navigateToCitations()
              }
              .appSecondaryActionButtonStyle()
            }

            if missingEvidenceCount > 0 {
              Text("含 \(missingEvidenceCount) 条失效证据 ID")
                .font(.caption2)
                .foregroundStyle(UIStyle.warningStatusColor)
            }
          }
        }
        .padding(8)
        .appChipGlass()
      }
    }
  }

  private func acceptRecommendation(for todo: TodoItem) {
    guard automationPermissionPolicy != .manualOnly else {
      handledRecommendationTodoIDs.insert(todo.id)
      appendAutomationAudit(
        action: .recommendationBlocked,
        status: .blocked,
        todo: todo,
        summary: "策略为仅手动，已阻止自动建议采用。"
      )
      message = "当前策略为“仅手动”，请手动更新任务状态。"
      return
    }

    if todo.status == .todo {
      setTodoStatus(todo, to: .doing)
    }
    if todo.scheduledAt == nil {
      todo.scheduledAt = .now
      todo.updatedAt = .now
      document.updatedAt = .now
    }
    handledRecommendationTodoIDs.insert(todo.id)
    appendAutomationAudit(
      action: .recommendationAccepted,
      status: .success,
      todo: todo,
      summary: "已采用执行建议并更新任务状态。"
    )
  }

  private func dismissRecommendation(for todo: TodoItem) {
    handledRecommendationTodoIDs.insert(todo.id)
    appendAutomationAudit(
      action: .recommendationDismissed,
      status: .success,
      todo: todo,
      summary: "已忽略执行建议。"
    )
  }

  private var syncOwnershipPolicy: SyncOwnershipPolicy {
    SyncOwnershipPolicy(rawValue: document.syncOwnershipPolicyRaw) ?? .localWins
  }

  private var automationPermissionPolicy: AutomationPermissionPolicy {
    AutomationPermissionPolicy(rawValue: document.automationPermissionPolicyRaw) ?? .assistive
  }

  private var syncOwnershipPolicyBinding: Binding<SyncOwnershipPolicy> {
    Binding(
      get: { syncOwnershipPolicy },
      set: { newValue in
        document.syncOwnershipPolicyRaw = newValue.rawValue
        document.updatedAt = .now
      }
    )
  }

  private var automationPermissionPolicyBinding: Binding<AutomationPermissionPolicy> {
    Binding(
      get: { automationPermissionPolicy },
      set: { newValue in
        document.automationPermissionPolicyRaw = newValue.rawValue
        document.updatedAt = .now
      }
    )
  }

  private func syncOwnershipPolicyTitle(_ policy: SyncOwnershipPolicy) -> String {
    switch policy {
    case .localWins:
      return "本地优先"
    case .remoteWins:
      return "远端优先"
    case .manualReview:
      return "人工确认"
    }
  }

  private func automationPermissionPolicyTitle(_ policy: AutomationPermissionPolicy) -> String {
    switch policy {
    case .manualOnly:
      return "仅手动"
    case .assistive:
      return "辅助模式"
    case .fullAuto:
      return "全自动"
    }
  }

  private func automationAuditStatusTitle(_ status: AutomationAuditStatus) -> String {
    switch status {
    case .pending:
      return "待审"
    case .success:
      return "通过"
    case .blocked:
      return "阻止"
    }
  }

  private var executionClaimByID: [String: Claim] {
    Dictionary(uniqueKeysWithValues: document.claims.map { ($0.id.uuidString, $0) })
  }

  private var executionCitationByID: [String: Citation] {
    Dictionary(uniqueKeysWithValues: document.citations.map { ($0.id.uuidString, $0) })
  }

  private func executionLinkedClaims(for todo: TodoItem) -> [Claim] {
    todo.linkedClaimIDs.compactMap { executionClaimByID[$0] }
  }

  private func executionLinkedCitations(for todo: TodoItem) -> [Citation] {
    todo.linkedCitationIDs.compactMap { executionCitationByID[$0] }
  }

  private func executionMissingEvidenceCount(for todo: TodoItem) -> Int {
    let missingClaimCount = todo.linkedClaimIDs.filter { executionClaimByID[$0] == nil }.count
    let missingCitationCount = todo.linkedCitationIDs.filter { executionCitationByID[$0] == nil }.count
    return missingClaimCount + missingCitationCount
  }

  private func executionCitationTitle(_ citation: Citation) -> String {
    if let title = citation.title?.trimmingCharacters(in: .whitespacesAndNewlines), title.isEmpty == false {
      return title
    }
    if citation.url.isEmpty == false {
      return citation.url
    }
    return "（未命名引用）"
  }

  private func navigateToTodoEvidenceEditor(_ todo: TodoItem) {
    selectedTodoID = todo.id
    #if os(macOS)
      selectedRoute = .todos
    #else
      selectedMainTab = .todos
    #endif
  }

  private func navigateToCitations() {
    #if os(macOS)
      selectedRoute = .citations
    #else
      selectedMainTab = .citations
    #endif
  }

  private var syncActionButtonTitle: String {
    switch automationPermissionPolicy {
    case .fullAuto:
      return "同步(模拟)"
    case .assistive, .manualOnly:
      return "送审(模拟)"
    }
  }

  private func pendingReviewTitle(_ review: PendingSyncReview) -> String {
    guard let todo = document.todos.first(where: { $0.id == review.todoID }) else {
      return "任务已删除"
    }
    return "\(todo.title.isEmpty ? "（无标题）" : todo.title) → \(review.remoteRecord.title)"
  }

  private func navigateToPendingReviewTodo(_ review: PendingSyncReview) {
    guard let todo = document.todos.first(where: { $0.id == review.todoID }) else { return }
    navigateToTodoEvidenceEditor(todo)
  }

  private func keepLocalForPendingReview(_ review: PendingSyncReview) {
    let todo = document.todos.first(where: { $0.id == review.todoID })
    pendingSyncReviewsByTodoID.removeValue(forKey: review.todoID)
    appendAutomationAudit(
      action: .syncKeptLocal,
      status: .success,
      todo: todo,
      summary: "人工审核：保留本地版本。",
      note: review.reason
    )
    message = "已保留本地版本。"
  }

  private func applyRemoteForPendingReview(_ review: PendingSyncReview) {
    guard let todo = document.todos.first(where: { $0.id == review.todoID }) else {
      pendingSyncReviewsByTodoID.removeValue(forKey: review.todoID)
      return
    }

    ExternalTaskMapping.applyExternalRecord(review.remoteRecord, to: todo)
    pendingSyncReviewsByTodoID.removeValue(forKey: review.todoID)
    document.updatedAt = .now
    appendAutomationAudit(
      action: .syncAppliedRemote,
      status: .success,
      todo: todo,
      summary: "人工审核：应用远端版本。",
      note: review.reason
    )
    message = "已应用远端版本。"
  }

  private func enqueuePendingSyncReview(
    for todo: TodoItem,
    remoteRecord: ExternalTaskRecord,
    reason: String
  ) {
    pendingSyncReviewsByTodoID[todo.id] = PendingSyncReview(
      todoID: todo.id,
      remoteRecord: remoteRecord,
      reason: reason
    )
    appendAutomationAudit(
      action: .syncQueuedForReview,
      status: .pending,
      todo: todo,
      summary: "已加入待审核队列。",
      note: reason
    )
  }

  private func appendAutomationAudit(
    action: AutomationAuditAction,
    status: AutomationAuditStatus,
    todo: TodoItem?,
    summary: String,
    note: String? = nil
  ) {
    let entry = AutomationAuditEntry(
      actionRaw: action.rawValue,
      statusRaw: status.rawValue,
      summary: summary,
      targetTodoIDRaw: todo?.id.uuidString,
      reviewerNote: note
    )
    entry.document = document
    modelContext.insert(entry)
    document.updatedAt = .now
  }

  private func syncTodoWithMockRemote(_ todo: TodoItem) {
    let remoteStatus = todo.statusRaw == TodoStatus.todo.rawValue ? TodoStatus.doing.rawValue : TodoStatus.todo.rawValue
    let remoteTitle = todo.title.isEmpty ? "Remote Task" : "\(todo.title)（远端）"
    let remoteRecord = ExternalTaskRecord(
      provider: .mock,
      externalID: todo.externalSyncID ?? "mock-\(todo.id.uuidString.prefix(8))",
      title: remoteTitle,
      notes: todo.detail,
      estimatedMinutes: todo.estimatedMinutes,
      statusRaw: remoteStatus,
      priorityRaw: todo.priorityRaw,
      scheduledAt: todo.scheduledAt,
      dueAt: todo.dueAt,
      sourceUpdatedAt: .now
    )

    switch automationPermissionPolicy {
    case .manualOnly:
      enqueuePendingSyncReview(
        for: todo,
        remoteRecord: remoteRecord,
        reason: "策略为“仅手动”，禁止自动同步。"
      )
      message = "当前策略为“仅手动”，已加入待审核队列。"
      return
    case .assistive:
      enqueuePendingSyncReview(
        for: todo,
        remoteRecord: remoteRecord,
        reason: "策略为“辅助模式”，需人工审核后应用。"
      )
      message = "已加入待审核队列，等待人工确认。"
      return
    case .fullAuto:
      break
    }

    let resolution = SyncConflictResolver.resolve(
      local: todo,
      remote: remoteRecord,
      policy: syncOwnershipPolicy
    )

    if resolution.requiresManualReview {
      enqueuePendingSyncReview(
        for: todo,
        remoteRecord: remoteRecord,
        reason: "冲突策略为“人工确认”，需人工审核。"
      )
      message = "检测到同步冲突，已加入待审核队列。"
      return
    }

    SyncConflictResolver.apply(resolution, to: todo)
    document.updatedAt = .now
    appendAutomationAudit(
      action: .syncAppliedByPolicy,
      status: .success,
      todo: todo,
      summary: "已按“\(syncOwnershipPolicyTitle(syncOwnershipPolicy))”策略自动同步。"
    )
    message = "已按“\(syncOwnershipPolicyTitle(syncOwnershipPolicy))”策略完成同步。"
  }
}
