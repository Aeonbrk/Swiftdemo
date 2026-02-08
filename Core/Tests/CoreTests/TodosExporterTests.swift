import Foundation
import Testing

@testable import Core

@Test func todosLegacyCSVRemainsBackwardCompatible() {
  let scheduledAt = Date(timeIntervalSince1970: 100)
  let dueAt = Date(timeIntervalSince1970: 200)
  let completedAt = Date(timeIntervalSince1970: 300)

  let todo = TodoItem(
    title: "Task",
    detail: "Detail",
    estimatedMinutes: 30,
    statusRaw: "done",
    priorityRaw: "high",
    frequencyRaw: "once",
    scheduledAt: scheduledAt,
    dueAt: dueAt,
    completedAt: completedAt
  )

  let csv = TodosExporter.csv(todos: [todo])
  let expected =
    "Title,Detail,EstimatedMinutes,Frequency,Status,ScheduledAt,DueAt\n"
    + "Task,Detail,30,once,done,\(scheduledAt.ISO8601Format()),\(dueAt.ISO8601Format())\n"
  #expect(csv == expected)
}

@Test func todosExtendedCSVIncludesExecutionFieldsAndEscapes() {
  let createdAt = Date(timeIntervalSince1970: 400)
  let updatedAt = Date(timeIntervalSince1970: 500)

  let todo = TodoItem(
    title: "a, \"b\"",
    detail: "line1\nline2",
    estimatedMinutes: nil,
    statusRaw: "legacy-status",
    priorityRaw: nil,
    frequencyRaw: "every,day",
    scheduledAt: nil,
    dueAt: nil,
    completedAt: nil,
    createdAt: createdAt,
    updatedAt: updatedAt
  )

  let csv = TodosExporter.csvExtended(todos: [todo])
  let expected =
    "Title,Detail,EstimatedMinutes,Frequency,Status,ScheduledAt,DueAt,Priority,CompletedAt,CreatedAt,UpdatedAt\n"
    + "\"a, \"\"b\"\"\",line1<br>line2,,\"every,day\",todo,,,medium,,\(createdAt.ISO8601Format()),"
    + "\(updatedAt.ISO8601Format())\n"
  #expect(csv == expected)
}
