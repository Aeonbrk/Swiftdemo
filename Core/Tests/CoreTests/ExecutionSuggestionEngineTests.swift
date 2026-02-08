import Foundation
import Testing

@testable import Core

@Test func executionSuggestionsRankByDueEffortStatusAndPriority() {
  let now = Date(timeIntervalSince1970: 1_000_000)
  let day: TimeInterval = 24 * 60 * 60

  let overdueHigh = TodoItem(
    title: "Overdue High",
    detail: "Task A",
    estimatedMinutes: 25,
    statusRaw: TodoStatus.todo.rawValue,
    priorityRaw: TodoPriority.high.rawValue,
    dueAt: now.addingTimeInterval(-day)
  )
  let doingSoon = TodoItem(
    title: "Doing Soon",
    detail: "Task B",
    estimatedMinutes: 45,
    statusRaw: TodoStatus.doing.rawValue,
    priorityRaw: TodoPriority.medium.rawValue,
    dueAt: now.addingTimeInterval(day)
  )
  let lowUnscheduled = TodoItem(
    title: "Low Unscheduled",
    detail: "Task C",
    estimatedMinutes: 180,
    statusRaw: TodoStatus.todo.rawValue,
    priorityRaw: TodoPriority.low.rawValue
  )

  let recommendations = ExecutionSuggestionEngine.recommendations(
    for: [lowUnscheduled, doingSoon, overdueHigh],
    now: now,
    limit: 3
  )

  #expect(recommendations.count == 3)
  #expect(recommendations[0].todoID == overdueHigh.id)
  #expect(recommendations[1].todoID == doingSoon.id)
  #expect(recommendations[2].todoID == lowUnscheduled.id)
  #expect(recommendations[0].reasons.contains("overdue"))
  #expect(recommendations[0].reasons.contains("high_priority"))
}

@Test func executionSuggestionsExcludeDoneAndBlockedTodos() {
  let actionable = TodoItem(
    title: "Actionable",
    detail: "Task",
    statusRaw: TodoStatus.todo.rawValue,
    priorityRaw: TodoPriority.medium.rawValue
  )
  let done = TodoItem(
    title: "Done",
    detail: "Task",
    statusRaw: TodoStatus.done.rawValue,
    priorityRaw: TodoPriority.high.rawValue
  )
  let blocked = TodoItem(
    title: "Blocked",
    detail: "Task",
    statusRaw: TodoStatus.blocked.rawValue,
    priorityRaw: TodoPriority.high.rawValue
  )

  let recommendations = ExecutionSuggestionEngine.recommendations(
    for: [actionable, done, blocked],
    now: Date(timeIntervalSince1970: 1_000_000),
    limit: 5
  )

  #expect(recommendations.count == 1)
  #expect(recommendations[0].todoID == actionable.id)
}
