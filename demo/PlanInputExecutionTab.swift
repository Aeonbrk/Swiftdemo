import Core
import Foundation
import SwiftData
import SwiftUI

enum ExecutionDashboardFilter: String, CaseIterable, Identifiable, Sendable {
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

struct PendingSyncReview: Identifiable, Sendable {
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
  var todayExecutionView: some View {
    let scoreByTodoID = executionScoreByTodoID
    let evidenceLookup = executionEvidenceLookup

    return AppRouteScaffold {
      workflowProgressView
      executionToolbar
      executionQualityIssuePanel

      if !executionSuggestionRows.isEmpty {
        executionRecommendationPanel
      }

      if executionFilteredTodos.isEmpty {
        AppPanelCard {
          AppEmptyStatePanel(
            title: "当前筛选下无任务",
            systemImage: "bolt.slash",
            description: "切换筛选条件，或先在“整理产物”里创建任务。"
          )
        }
      } else {
        AppSplitWorkspace(leadingMinWidth: UIStyle.contentColumnMinWidth) {
          executionList(scoreByTodoID: scoreByTodoID, evidenceLookup: evidenceLookup)
        } trailing: {
          executionDetail
        }
      }

      if isExecutionAdvancedExpanded {
        executionAdvancedPanel
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

        Button {
          createTodo()
          if let todo = selectedTodo {
            setTodoStatus(todo, to: .todo)
          }
        } label: {
          Label("新建任务", systemImage: "plus")
        }
        .appPrimaryActionButtonStyle()

        Button(role: .destructive) {
          deleteSelectedTodo()
        } label: {
          Label("删除任务", systemImage: "trash")
        }
        .appSecondaryActionButtonStyle()
        .disabled(selectedTodo == nil)

        Spacer(minLength: UIStyle.compactSpacing)

        if !executionSuggestionRows.isEmpty {
          Text("建议 \(executionSuggestionRows.count) 项")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Button {
          withAnimation(.snappy(duration: 0.2)) {
            isExecutionAdvancedExpanded.toggle()
          }
        } label: {
          Label(isExecutionAdvancedExpanded ? "收起高级" : "高级", systemImage: "slider.horizontal.3")
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
      activeIDs.contains($0.todoID) && !handledRecommendationTodoIDs.contains($0.todoID)
    }
  }

  private var executionSuggestionRows: [(recommendation: TodoRecommendation, todo: TodoItem)] {
    let todoByID = Dictionary(uniqueKeysWithValues: document.todos.map { ($0.id, $0) })
    return pendingExecutionRecommendations
      .prefix(3)
      .compactMap { recommendation in
        todoByID[recommendation.todoID].map {
          (recommendation: recommendation, todo: $0)
        }
      }
  }

  var executionScoreByTodoID: [UUID: Int] {
    Dictionary(uniqueKeysWithValues: executionRecommendations.map { ($0.todoID, $0.score) })
  }

  private var executionEvidenceLookup: ExecutionEvidenceLookup {
    ExecutionEvidenceLookup(
      claimsByID: Dictionary(uniqueKeysWithValues: document.claims.map { ($0.id.uuidString, $0) }),
      citationsByID: Dictionary(uniqueKeysWithValues: document.citations.map { ($0.id.uuidString, $0) })
    )
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

  private func executionList(
    scoreByTodoID: [UUID: Int],
    evidenceLookup: ExecutionEvidenceLookup
  ) -> some View {
    List(selection: $selectedTodoID) {
      ForEach(executionFilteredTodos, id: \.id) { todo in
        executionRow(todo, scoreByTodoID: scoreByTodoID, evidenceLookup: evidenceLookup)
          .padding(.horizontal, UIStyle.panelInnerPadding)
          .padding(.vertical, UIStyle.listRowVerticalPadding)
          .appRowGlass()
          .tag(todo.id)
          .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
      .onDelete(perform: deleteTodos)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .appListContainerGlass()
  }

  private var executionDetail: some View {
    Group {
      if let selectedTodo {
        todoEditor(for: selectedTodo)
      } else if executionFilteredTodos.isEmpty {
        AppEmptyStatePanel(
          title: "暂无任务详情",
          systemImage: "checklist",
          description: "请先创建任务或切换筛选条件。"
        )
      } else {
        AppEmptyStatePanel(
          title: "请选择任务",
          systemImage: "checkmark.circle"
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var pendingSyncReviews: [PendingSyncReview] {
    pendingSyncReviewsByTodoID.values.sorted(by: { $0.createdAt > $1.createdAt })
  }

  private var recentAutomationAudits: [AutomationAuditEntry] {
    document.automationAudits.sorted(by: { $0.createdAt > $1.createdAt })
  }

  private var executionAdvancedPanel: some View {
    AppPanelCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("高级执行策略")
          .font(.headline)

        HStack(spacing: UIStyle.compactSpacing) {
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
        }

        if !pendingSyncReviews.isEmpty {
          executionPendingReviewPanel
        }

        if !recentAutomationAudits.isEmpty {
          executionAutomationAuditPanel
        }
      }
    }
  }

  private var executionPendingReviewPanel: some View {
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

  private var executionAutomationAuditPanel: some View {
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
