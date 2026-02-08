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
    let scoreByTodoID = executionScoreByTodoID
    let evidenceLookup = executionEvidenceLookup

    return AppRouteScaffold {
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
            executionRow(todo, scoreByTodoID: scoreByTodoID, evidenceLookup: evidenceLookup)
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

  private func executionRow(
    _ todo: TodoItem,
    scoreByTodoID: [UUID: Int],
    evidenceLookup: ExecutionEvidenceLookup
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      executionRowHeader(for: todo)
      executionRowDetail(for: todo)
      executionRowMeta(for: todo, scoreByTodoID: scoreByTodoID)
      executionRowEvidence(for: todo, evidenceLookup: evidenceLookup)
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

  private func executionRowMeta(for todo: TodoItem, scoreByTodoID: [UUID: Int]) -> some View {
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
}
