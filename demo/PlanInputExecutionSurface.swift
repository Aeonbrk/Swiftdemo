import Core
import SwiftUI

private struct ExecutionTodoSummary {
  let todo: Int
  let doing: Int
  let blocked: Int
  let done: Int
}

extension PlanInputView {
  var executionHero: some View {
    let summary = executionTodoSummary

    return AppPanelCard {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        Text("今日执行")
          .font(.headline)
        Text("先启动一项最重要任务，再持续更新状态与执行证据。")
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack(spacing: UIStyle.compactSpacing) {
          executionSummaryChip(title: "进行中", count: summary.doing, color: UIStyle.positiveStatusColor)
          executionSummaryChip(title: "待办", count: summary.todo, color: .secondary)
          executionSummaryChip(title: "阻塞", count: summary.blocked, color: UIStyle.warningStatusColor)
          executionSummaryChip(title: "已完成", count: summary.done, color: .secondary)
        }
      }
    }
  }

  var executionPrimaryActionRow: some View {
    AppActionBar {
      HStack(spacing: UIStyle.compactSpacing) {
        Picker("筛选", selection: $executionFilter) {
          ForEach(ExecutionDashboardFilter.allCases, id: \.self) { filter in
            Text(filter.title).tag(filter)
          }
        }
        .pickerStyle(.segmented)

        Button {
          focusOrStartNextTodo()
        } label: {
          Label("开始下一任务", systemImage: "play.fill")
        }
        .appPrimaryActionButtonStyle()
        .disabled(executionFilteredTodos.isEmpty)

        Button {
          createTodo()
          if let todo = selectedTodo {
            setTodoStatus(todo, to: .todo)
          }
        } label: {
          Label("新建任务", systemImage: "plus")
        }
        .appSecondaryActionButtonStyle()

        Spacer(minLength: UIStyle.compactSpacing)

        Text("共 \(executionFilteredTodos.count) 项")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  var executionSecondaryPanels: some View {
    Group {
      if !executionSuggestionRows.isEmpty || !pendingSyncReviews.isEmpty || !recentAutomationAudits.isEmpty {
        DisclosureGroup(
          isExpanded: $isExecutionAdvancedExpanded,
          content: {
            VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
              if !executionSuggestionRows.isEmpty {
                executionRecommendationPanel
              }
              executionAdvancedPanel
            }
            .padding(.top, UIStyle.compactSpacing)
          },
          label: {
            Text("更多与高级")
              .font(.headline)
          }
        )
        .padding(UIStyle.panelInnerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appPanelGlass()
      }
    }
  }

  private var executionTodoSummary: ExecutionTodoSummary {
    let todoCount = document.todos.filter { $0.status == .todo }.count
    let doingCount = document.todos.filter { $0.status == .doing }.count
    let blockedCount = document.todos.filter { $0.status == .blocked }.count
    let doneCount = document.todos.filter { $0.status == .done || $0.completedAt != nil }.count
    return ExecutionTodoSummary(
      todo: todoCount,
      doing: doingCount,
      blocked: blockedCount,
      done: doneCount
    )
  }

  private func executionSummaryChip(title: String, count: Int, color: Color) -> some View {
    HStack(spacing: 6) {
      Circle()
        .fill(color)
        .frame(width: 6, height: 6)
      Text("\(title) \(count)")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .appChipGlass()
  }

  private func focusOrStartNextTodo() {
    if let doingTodo = executionFilteredTodos.first(where: { $0.status == .doing }) {
      selectedTodoID = doingTodo.id
      return
    }

    guard let nextTodo = executionFilteredTodos.first(where: { $0.status != .done && $0.status != .blocked }) else {
      return
    }

    selectedTodoID = nextTodo.id
    setTodoStatus(nextTodo, to: .doing)
  }
}
