import Core
import Foundation

extension PlanInputView {
  var executionFilteredTodos: [TodoItem] {
    let scoreByTodoID = executionScoreByTodoID
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: .now)
    let todos = document.todos.filter {
      matchesExecutionFilter($0, calendar: calendar, startOfToday: startOfToday)
    }
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

  private func matchesExecutionFilter(
    _ todo: TodoItem,
    calendar: Calendar,
    startOfToday: Date
  ) -> Bool {
    let isDone = todo.status == .done || todo.completedAt != nil
    let isBlocked = todo.status == .blocked
    let isOverdue = todo.dueAt.map { $0 < startOfToday } ?? false
    let isTodayScheduled = [todo.scheduledAt, todo.dueAt]
      .compactMap { $0 }
      .contains(where: { calendar.isDateInToday($0) })
    let hasNoSchedule = todo.scheduledAt == nil && todo.dueAt == nil

    switch executionFilter {
    case .today:
      return !isDone && !isBlocked && !isOverdue
        && (isTodayScheduled || hasNoSchedule)
    case .overdue:
      return !isDone && isOverdue
    case .done:
      return isDone
    case .blocked:
      return isBlocked && !isDone
    }
  }

  private func executionSortDate(for todo: TodoItem) -> Date {
    todo.dueAt ?? todo.scheduledAt ?? todo.createdAt
  }
}
