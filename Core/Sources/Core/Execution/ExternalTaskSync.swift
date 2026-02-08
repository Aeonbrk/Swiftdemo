import Foundation

public enum ExternalTaskProvider: String, Codable, Sendable, CaseIterable {
  case reminders
  case calendar
  case mock
}

public struct ExternalTaskRecord: Equatable, Sendable {
  public var provider: ExternalTaskProvider
  public var externalID: String
  public var title: String
  public var notes: String
  public var estimatedMinutes: Int?
  public var statusRaw: String
  public var priorityRaw: String?
  public var scheduledAt: Date?
  public var dueAt: Date?
  public var sourceUpdatedAt: Date?

  public init(
    provider: ExternalTaskProvider,
    externalID: String,
    title: String,
    notes: String,
    estimatedMinutes: Int?,
    statusRaw: String,
    priorityRaw: String?,
    scheduledAt: Date?,
    dueAt: Date?,
    sourceUpdatedAt: Date?
  ) {
    self.provider = provider
    self.externalID = externalID
    self.title = title
    self.notes = notes
    self.estimatedMinutes = estimatedMinutes
    self.statusRaw = statusRaw
    self.priorityRaw = priorityRaw
    self.scheduledAt = scheduledAt
    self.dueAt = dueAt
    self.sourceUpdatedAt = sourceUpdatedAt
  }
}

public protocol ExternalTaskSyncAdapter: Sendable {
  var provider: ExternalTaskProvider { get }
  func push(task: ExternalTaskRecord) async throws -> ExternalTaskRecord
  func pull(externalID: String) async throws -> ExternalTaskRecord?
}

public struct NoopExternalTaskSyncAdapter: ExternalTaskSyncAdapter {
  public let provider: ExternalTaskProvider

  public init(provider: ExternalTaskProvider = .mock) {
    self.provider = provider
  }

  public func push(task: ExternalTaskRecord) async throws -> ExternalTaskRecord {
    task
  }

  public func pull(externalID: String) async throws -> ExternalTaskRecord? {
    nil
  }
}

public enum ExternalTaskMapping {
  public static func toExternalRecord(
    todo: TodoItem,
    provider: ExternalTaskProvider
  ) -> ExternalTaskRecord {
    ExternalTaskRecord(
      provider: provider,
      externalID: todo.externalSyncID ?? todo.id.uuidString,
      title: todo.title,
      notes: todo.detail,
      estimatedMinutes: todo.estimatedMinutes,
      statusRaw: todo.statusRaw,
      priorityRaw: todo.priorityRaw,
      scheduledAt: todo.scheduledAt,
      dueAt: todo.dueAt,
      sourceUpdatedAt: todo.externalSyncUpdatedAt ?? todo.updatedAt
    )
  }

  public static func applyExternalRecord(_ record: ExternalTaskRecord, to todo: TodoItem) {
    todo.title = record.title
    todo.detail = record.notes
    todo.estimatedMinutes = record.estimatedMinutes
    todo.statusRaw = record.statusRaw
    todo.priorityRaw = record.priorityRaw
    todo.scheduledAt = record.scheduledAt
    todo.dueAt = record.dueAt
    todo.externalSyncSourceRaw = record.provider.rawValue
    todo.externalSyncID = record.externalID
    todo.externalSyncUpdatedAt = record.sourceUpdatedAt
    todo.updatedAt = .now
  }
}

public enum SyncOwnershipPolicy: String, Codable, Sendable, CaseIterable {
  case localWins
  case remoteWins
  case manualReview
}

public struct SyncConflictResolution: Equatable, Sendable {
  public var policy: SyncOwnershipPolicy
  public var mergedRecord: ExternalTaskRecord
  public var requiresManualReview: Bool

  public init(
    policy: SyncOwnershipPolicy,
    mergedRecord: ExternalTaskRecord,
    requiresManualReview: Bool
  ) {
    self.policy = policy
    self.mergedRecord = mergedRecord
    self.requiresManualReview = requiresManualReview
  }
}

public enum SyncConflictResolver {
  public static func resolve(
    local: TodoItem,
    remote: ExternalTaskRecord,
    policy: SyncOwnershipPolicy
  ) -> SyncConflictResolution {
    let localRecord = ExternalTaskRecord(
      provider: remote.provider,
      externalID: remote.externalID,
      title: local.title,
      notes: local.detail,
      estimatedMinutes: local.estimatedMinutes,
      statusRaw: local.statusRaw,
      priorityRaw: local.priorityRaw,
      scheduledAt: local.scheduledAt,
      dueAt: local.dueAt,
      sourceUpdatedAt: local.updatedAt
    )

    switch policy {
    case .localWins:
      return SyncConflictResolution(
        policy: policy,
        mergedRecord: localRecord,
        requiresManualReview: false
      )
    case .remoteWins:
      return SyncConflictResolution(
        policy: policy,
        mergedRecord: remote,
        requiresManualReview: false
      )
    case .manualReview:
      return SyncConflictResolution(
        policy: policy,
        mergedRecord: localRecord,
        requiresManualReview: true
      )
    }
  }

  public static func apply(_ resolution: SyncConflictResolution, to todo: TodoItem) {
    guard resolution.requiresManualReview == false else { return }
    ExternalTaskMapping.applyExternalRecord(resolution.mergedRecord, to: todo)
  }
}
