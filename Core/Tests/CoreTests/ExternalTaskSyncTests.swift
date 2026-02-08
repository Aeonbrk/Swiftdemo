import Foundation
import Testing

@testable import Core

@Test func externalTaskMappingBuildsProviderRecordFromTodo() {
  let todo = TodoItem(
    title: "Review chapter",
    detail: "Ownership and borrowing",
    estimatedMinutes: 40,
    statusRaw: "doing",
    priorityRaw: "high",
    frequencyRaw: "once",
    scheduledAt: Date(timeIntervalSince1970: 1_739_155_200),
    dueAt: Date(timeIntervalSince1970: 1_739_241_600)
  )

  let record = ExternalTaskMapping.toExternalRecord(todo: todo, provider: .mock)
  #expect(record.provider == .mock)
  #expect(record.externalID == todo.externalSyncID ?? todo.id.uuidString)
  #expect(record.title == todo.title)
  #expect(record.notes == todo.detail)
  #expect(record.statusRaw == "doing")
  #expect(record.priorityRaw == "high")
}

@Test func externalTaskMappingAppliesRecordAndStoresSyncMetadata() {
  let todo = TodoItem(
    title: "Old",
    detail: "Old detail",
    estimatedMinutes: 15,
    statusRaw: "todo",
    priorityRaw: "low",
    frequencyRaw: "once"
  )

  let record = ExternalTaskRecord(
    provider: .calendar,
    externalID: "evt-123",
    title: "New title",
    notes: "New detail",
    estimatedMinutes: 25,
    statusRaw: "doing",
    priorityRaw: "medium",
    scheduledAt: Date(timeIntervalSince1970: 1_739_200_000),
    dueAt: Date(timeIntervalSince1970: 1_739_260_000),
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_739_210_000)
  )

  ExternalTaskMapping.applyExternalRecord(record, to: todo)
  #expect(todo.title == "New title")
  #expect(todo.detail == "New detail")
  #expect(todo.estimatedMinutes == 25)
  #expect(todo.statusRaw == "doing")
  #expect(todo.priorityRaw == "medium")
  #expect(todo.externalSyncSourceRaw == "calendar")
  #expect(todo.externalSyncID == "evt-123")
  #expect(todo.externalSyncUpdatedAt == Date(timeIntervalSince1970: 1_739_210_000))
}

@Test func syncConflictResolverHonorsLocalWinsPolicy() {
  let todo = TodoItem(
    title: "Local title",
    detail: "Local detail",
    estimatedMinutes: 30,
    statusRaw: "doing",
    priorityRaw: "high",
    frequencyRaw: "once",
    externalSyncID: "evt-local"
  )

  let remote = ExternalTaskRecord(
    provider: .calendar,
    externalID: "evt-remote",
    title: "Remote title",
    notes: "Remote detail",
    estimatedMinutes: 15,
    statusRaw: "todo",
    priorityRaw: "low",
    scheduledAt: nil,
    dueAt: nil,
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_739_220_000)
  )

  let resolution = SyncConflictResolver.resolve(local: todo, remote: remote, policy: .localWins)
  #expect(resolution.requiresManualReview == false)
  #expect(resolution.mergedRecord.title == "Local title")
  #expect(resolution.mergedRecord.externalID == "evt-remote")
}

@Test func syncConflictResolverMarksManualReviewWhenConfigured() {
  let todo = TodoItem(
    title: "Local title",
    detail: "Local detail",
    estimatedMinutes: 30,
    statusRaw: "doing",
    priorityRaw: "high",
    frequencyRaw: "once"
  )

  let remote = ExternalTaskRecord(
    provider: .mock,
    externalID: "evt-remote",
    title: "Remote title",
    notes: "Remote detail",
    estimatedMinutes: 10,
    statusRaw: "todo",
    priorityRaw: "low",
    scheduledAt: nil,
    dueAt: nil,
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_739_220_000)
  )

  let resolution = SyncConflictResolver.resolve(local: todo, remote: remote, policy: .manualReview)
  #expect(resolution.requiresManualReview)
  #expect(resolution.mergedRecord.title == "Local title")
}
