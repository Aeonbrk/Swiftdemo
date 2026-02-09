import Core
import SwiftData
import SwiftUI

extension PlanInputView {
  func acceptRecommendation(for todo: TodoItem) {
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

  func dismissRecommendation(for todo: TodoItem) {
    handledRecommendationTodoIDs.insert(todo.id)
    appendAutomationAudit(
      action: .recommendationDismissed,
      status: .success,
      todo: todo,
      summary: "已忽略执行建议。"
    )
  }

  var syncOwnershipPolicy: SyncOwnershipPolicy {
    SyncOwnershipPolicy(rawValue: document.syncOwnershipPolicyRaw) ?? .localWins
  }

  var automationPermissionPolicy: AutomationPermissionPolicy {
    AutomationPermissionPolicy(rawValue: document.automationPermissionPolicyRaw) ?? .assistive
  }

  var syncOwnershipPolicyBinding: Binding<SyncOwnershipPolicy> {
    Binding(
      get: { syncOwnershipPolicy },
      set: { newValue in
        document.syncOwnershipPolicyRaw = newValue.rawValue
        document.updatedAt = .now
      }
    )
  }

  var automationPermissionPolicyBinding: Binding<AutomationPermissionPolicy> {
    Binding(
      get: { automationPermissionPolicy },
      set: { newValue in
        document.automationPermissionPolicyRaw = newValue.rawValue
        document.updatedAt = .now
      }
    )
  }

  func syncOwnershipPolicyTitle(_ policy: SyncOwnershipPolicy) -> String {
    switch policy {
    case .localWins:
      return "本地优先"
    case .remoteWins:
      return "远端优先"
    case .manualReview:
      return "人工确认"
    }
  }

  func automationPermissionPolicyTitle(_ policy: AutomationPermissionPolicy) -> String {
    switch policy {
    case .manualOnly:
      return "仅手动"
    case .assistive:
      return "辅助模式"
    case .fullAuto:
      return "全自动"
    }
  }

  func automationAuditStatusTitle(_ status: AutomationAuditStatus) -> String {
    switch status {
    case .pending:
      return "待审"
    case .success:
      return "通过"
    case .blocked:
      return "阻止"
    }
  }

  var syncActionButtonTitle: String {
    switch automationPermissionPolicy {
    case .fullAuto:
      return "同步(模拟)"
    case .assistive, .manualOnly:
      return "送审(模拟)"
    }
  }

  func pendingReviewTitle(_ review: PendingSyncReview) -> String {
    guard let todo = document.todos.first(where: { $0.id == review.todoID }) else {
      return "任务已删除"
    }
    return "\(todo.title.isEmpty ? "（无标题）" : todo.title) → \(review.remoteRecord.title)"
  }

  func navigateToPendingReviewTodo(_ review: PendingSyncReview) {
    guard let todo = document.todos.first(where: { $0.id == review.todoID }) else { return }
    navigateToTodoEvidenceEditor(todo)
  }

  func keepLocalForPendingReview(_ review: PendingSyncReview) {
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

  func applyRemoteForPendingReview(_ review: PendingSyncReview) {
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

  func syncTodoWithMockRemote(_ todo: TodoItem) {
    let remoteRecord = mockRemoteRecord(for: todo)
    if queueSyncByAutomationPolicyIfNeeded(for: todo, remoteRecord: remoteRecord) {
      return
    }

    let resolution = SyncConflictResolver.resolve(
      local: todo,
      remote: remoteRecord,
      policy: syncOwnershipPolicy
    )
    if queueSyncByConflictPolicyIfNeeded(for: todo, remoteRecord: remoteRecord, resolution: resolution) {
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

  private func mockRemoteRecord(for todo: TodoItem) -> ExternalTaskRecord {
    let remoteStatus = todo.statusRaw == TodoStatus.todo.rawValue ? TodoStatus.doing.rawValue : TodoStatus.todo.rawValue
    let remoteTitle = todo.title.isEmpty ? "Remote Task" : "\(todo.title)（远端）"
    return ExternalTaskRecord(
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
  }

  private func queueSyncByAutomationPolicyIfNeeded(for todo: TodoItem, remoteRecord: ExternalTaskRecord) -> Bool {
    switch automationPermissionPolicy {
    case .manualOnly:
      enqueuePendingSyncReview(
        for: todo,
        remoteRecord: remoteRecord,
        reason: "策略为“仅手动”，禁止自动同步。"
      )
      message = "当前策略为“仅手动”，已加入待审核队列。"
      return true
    case .assistive:
      enqueuePendingSyncReview(
        for: todo,
        remoteRecord: remoteRecord,
        reason: "策略为“辅助模式”，需人工审核后应用。"
      )
      message = "已加入待审核队列，等待人工确认。"
      return true
    case .fullAuto:
      return false
    }
  }

  private func queueSyncByConflictPolicyIfNeeded(
    for todo: TodoItem,
    remoteRecord: ExternalTaskRecord,
    resolution: SyncConflictResolution
  ) -> Bool {
    if !resolution.requiresManualReview {
      return false
    }
    enqueuePendingSyncReview(
      for: todo,
      remoteRecord: remoteRecord,
      reason: "冲突策略为“人工确认”，需人工审核。"
    )
    message = "检测到同步冲突，已加入待审核队列。"
    return true
  }
}
