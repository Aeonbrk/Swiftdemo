import Foundation
import SwiftData

public enum TodoStatus: String, CaseIterable, Sendable {
  case todo
  case doing
  case blocked
  case done
}

public enum TodoPriority: String, CaseIterable, Sendable {
  case low
  case medium
  case high
}

private enum TodoItemDefaults {
  static let status: TodoStatus = .todo
  static let priority: TodoPriority = .medium
}

@Model
public final class TodoItem {
  @Attribute(.unique)
  public var id: UUID

  public var title: String
  public var detail: String
  public var estimatedMinutes: Int?

  public var statusRaw: String
  public var priorityRaw: String?
  public var frequencyRaw: String

  public var scheduledAt: Date?
  public var dueAt: Date?
  public var completedAt: Date?

  public var externalSyncSourceRaw: String?
  public var externalSyncID: String?
  public var externalSyncUpdatedAt: Date?
  public var linkedClaimIDsRaw: String
  public var linkedCitationIDsRaw: String

  public var createdAt: Date
  public var updatedAt: Date

  public var document: PlanDocument?

  public var status: TodoStatus {
    get { Self.decodeStatus(from: statusRaw) }
    set { statusRaw = newValue.rawValue }
  }

  public var priority: TodoPriority {
    get { Self.decodePriority(from: priorityRaw) }
    set { priorityRaw = newValue.rawValue }
  }

  public var linkedClaimIDs: [String] {
    get { Self.decodeIDList(from: linkedClaimIDsRaw) }
    set { linkedClaimIDsRaw = Self.encodeIDList(from: newValue) }
  }

  public var linkedCitationIDs: [String] {
    get { Self.decodeIDList(from: linkedCitationIDsRaw) }
    set { linkedCitationIDsRaw = Self.encodeIDList(from: newValue) }
  }

  public init(
    title: String,
    detail: String,
    estimatedMinutes: Int? = nil,
    statusRaw: String = "todo",
    priorityRaw: String? = nil,
    frequencyRaw: String = "once",
    scheduledAt: Date? = nil,
    dueAt: Date? = nil,
    completedAt: Date? = nil,
    externalSyncSourceRaw: String? = nil,
    externalSyncID: String? = nil,
    externalSyncUpdatedAt: Date? = nil,
    linkedClaimIDsRaw: String = "",
    linkedCitationIDsRaw: String = "",
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.title = title
    self.detail = detail
    self.estimatedMinutes = estimatedMinutes
    self.statusRaw = statusRaw
    self.priorityRaw = priorityRaw
    self.frequencyRaw = frequencyRaw
    self.scheduledAt = scheduledAt
    self.dueAt = dueAt
    self.completedAt = completedAt
    self.externalSyncSourceRaw = externalSyncSourceRaw
    self.externalSyncID = externalSyncID
    self.externalSyncUpdatedAt = externalSyncUpdatedAt
    self.linkedClaimIDsRaw = linkedClaimIDsRaw
    self.linkedCitationIDsRaw = linkedCitationIDsRaw
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  public convenience init(
    title: String,
    detail: String,
    estimatedMinutes: Int? = nil,
    status: TodoStatus,
    priority: TodoPriority? = nil,
    frequencyRaw: String = "once",
    scheduledAt: Date? = nil,
    dueAt: Date? = nil,
    completedAt: Date? = nil,
    externalSyncSourceRaw: String? = nil,
    externalSyncID: String? = nil,
    externalSyncUpdatedAt: Date? = nil,
    linkedClaimIDsRaw: String = "",
    linkedCitationIDsRaw: String = "",
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.init(
      title: title,
      detail: detail,
      estimatedMinutes: estimatedMinutes,
      statusRaw: status.rawValue,
      priorityRaw: priority?.rawValue,
      frequencyRaw: frequencyRaw,
      scheduledAt: scheduledAt,
      dueAt: dueAt,
      completedAt: completedAt,
      externalSyncSourceRaw: externalSyncSourceRaw,
      externalSyncID: externalSyncID,
      externalSyncUpdatedAt: externalSyncUpdatedAt,
      linkedClaimIDsRaw: linkedClaimIDsRaw,
      linkedCitationIDsRaw: linkedCitationIDsRaw,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }

  private static func decodeStatus(from raw: String) -> TodoStatus {
    TodoStatus(rawValue: raw) ?? TodoItemDefaults.status
  }

  private static func decodePriority(from raw: String?) -> TodoPriority {
    guard let raw, raw.isEmpty == false else {
      return TodoItemDefaults.priority
    }
    return TodoPriority(rawValue: raw) ?? TodoItemDefaults.priority
  }

  private static func decodeIDList(from raw: String) -> [String] {
    normalizedUniqueIDs(raw.split(separator: ",").map { String($0) })
  }

  private static func encodeIDList(from ids: [String]) -> String {
    normalizedUniqueIDs(ids).joined(separator: ",")
  }

  private static func normalizedUniqueIDs(_ ids: [String]) -> [String] {
    Array(
      Set(
        ids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { $0.isEmpty == false }
      )
    )
    .sorted()
  }
}
