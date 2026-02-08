import Foundation

public struct TodoRecommendation: Equatable, Sendable {
  public let todoID: UUID
  public let score: Int
  public let reasons: [String]

  public init(todoID: UUID, score: Int, reasons: [String]) {
    self.todoID = todoID
    self.score = score
    self.reasons = reasons
  }
}

private struct SuggestionScorePart {
  let score: Int
  let reasons: [String]
}

public enum ExecutionSuggestionEngine {
  public static func recommendations(
    for todos: [TodoItem],
    now: Date = .now,
    limit: Int = 5
  ) -> [TodoRecommendation] {
    guard limit > 0 else { return [] }

    let candidates = todos
      .filter { isActionable($0) }
      .map { todo -> (todo: TodoItem, recommendation: TodoRecommendation) in
        let result = score(todo, now: now)
        return (
          todo: todo,
          recommendation: TodoRecommendation(todoID: todo.id, score: result.score, reasons: result.reasons)
        )
      }
      .sorted { lhs, rhs in
        if lhs.recommendation.score != rhs.recommendation.score {
          return lhs.recommendation.score > rhs.recommendation.score
        }

        let lhsDate = dueOrScheduleDate(for: lhs.todo)
        let rhsDate = dueOrScheduleDate(for: rhs.todo)
        if lhsDate != rhsDate {
          return lhsDate < rhsDate
        }

        let lhsPriority = priorityRank(lhs.todo.priority)
        let rhsPriority = priorityRank(rhs.todo.priority)
        if lhsPriority != rhsPriority {
          return lhsPriority > rhsPriority
        }

        if lhs.todo.createdAt != rhs.todo.createdAt {
          return lhs.todo.createdAt < rhs.todo.createdAt
        }

        return lhs.todo.id.uuidString < rhs.todo.id.uuidString
      }

    return candidates.prefix(limit).map(\.recommendation)
  }

  private static func score(_ todo: TodoItem, now: Date) -> (score: Int, reasons: [String]) {
    let parts = [
      statusPart(for: todo),
      priorityPart(for: todo),
      duePart(for: todo, now: now),
      scheduledPart(for: todo, now: now),
      effortPart(for: todo),
      unscheduledPart(for: todo)
    ]
    return combine(parts)
  }

  private static func statusPart(for todo: TodoItem) -> SuggestionScorePart {
    switch todo.status {
    case .doing:
      return SuggestionScorePart(score: 25, reasons: ["in_progress"])
    case .todo:
      return SuggestionScorePart(score: 10, reasons: ["todo_ready"])
    case .blocked, .done:
      return SuggestionScorePart(score: 0, reasons: [])
    }
  }

  private static func priorityPart(for todo: TodoItem) -> SuggestionScorePart {
    switch todo.priority {
    case .high:
      return SuggestionScorePart(score: 30, reasons: ["high_priority"])
    case .medium:
      return SuggestionScorePart(score: 15, reasons: ["medium_priority"])
    case .low:
      return SuggestionScorePart(score: 5, reasons: ["low_priority"])
    }
  }

  private static func duePart(for todo: TodoItem, now: Date) -> SuggestionScorePart {
    guard let dueAt = todo.dueAt else {
      return SuggestionScorePart(score: 0, reasons: [])
    }

    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: now)
    if dueAt < startOfToday {
      return SuggestionScorePart(score: 60, reasons: ["overdue"])
    }
    if calendar.isDateInToday(dueAt) {
      return SuggestionScorePart(score: 40, reasons: ["due_today"])
    }
    if dueAt < now.addingTimeInterval(2 * 24 * 60 * 60) {
      return SuggestionScorePart(score: 20, reasons: ["due_soon"])
    }

    return SuggestionScorePart(score: 0, reasons: [])
  }

  private static func scheduledPart(for todo: TodoItem, now: Date) -> SuggestionScorePart {
    guard let scheduledAt = todo.scheduledAt, Calendar.current.isDateInToday(scheduledAt) else {
      return SuggestionScorePart(score: 0, reasons: [])
    }

    return SuggestionScorePart(score: 15, reasons: ["scheduled_today"])
  }

  private static func effortPart(for todo: TodoItem) -> SuggestionScorePart {
    guard let estimatedMinutes = todo.estimatedMinutes else {
      return SuggestionScorePart(score: 0, reasons: [])
    }
    if estimatedMinutes <= 30 {
      return SuggestionScorePart(score: 20, reasons: ["quick_win"])
    }
    if estimatedMinutes <= 60 {
      return SuggestionScorePart(score: 10, reasons: ["moderate_effort"])
    }
    if estimatedMinutes > 120 {
      return SuggestionScorePart(score: -10, reasons: ["heavy_effort"])
    }

    return SuggestionScorePart(score: 0, reasons: [])
  }

  private static func unscheduledPart(for todo: TodoItem) -> SuggestionScorePart {
    if todo.dueAt == nil && todo.scheduledAt == nil {
      return SuggestionScorePart(score: -5, reasons: ["unscheduled"])
    }

    return SuggestionScorePart(score: 0, reasons: [])
  }

  private static func combine(_ parts: [SuggestionScorePart]) -> (score: Int, reasons: [String]) {
    let totalScore = parts.reduce(0) { $0 + $1.score }
    let reasons = parts.flatMap(\.reasons)
    return (score: totalScore, reasons: reasons)
  }

  private static func isActionable(_ todo: TodoItem) -> Bool {
    if todo.status == .done { return false }
    if todo.completedAt != nil { return false }
    if todo.status == .blocked { return false }
    return true
  }

  private static func dueOrScheduleDate(for todo: TodoItem) -> Date {
    todo.dueAt ?? todo.scheduledAt ?? .distantFuture
  }

  private static func priorityRank(_ priority: TodoPriority) -> Int {
    switch priority {
    case .high:
      3
    case .medium:
      2
    case .low:
      1
    }
  }
}
