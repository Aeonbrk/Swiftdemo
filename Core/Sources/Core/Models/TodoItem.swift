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
    get { TodoStatus(rawValue: statusRaw) ?? .todo }
    set { statusRaw = newValue.rawValue }
  }

  public var priority: TodoPriority {
    get { TodoPriority(rawValue: priorityRaw ?? "") ?? .medium }
    set { priorityRaw = newValue.rawValue }
  }

  public var linkedClaimIDs: [String] {
    get { Self.parseIDList(from: linkedClaimIDsRaw) }
    set { linkedClaimIDsRaw = Self.encodeIDList(newValue) }
  }

  public var linkedCitationIDs: [String] {
    get { Self.parseIDList(from: linkedCitationIDsRaw) }
    set { linkedCitationIDsRaw = Self.encodeIDList(newValue) }
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

  private static func parseIDList(from raw: String) -> [String] {
    normalizedIDs(raw.split(separator: ",").map { String($0) })
  }

  private static func encodeIDList(_ ids: [String]) -> String {
    normalizedIDs(ids).joined(separator: ",")
  }

  private static func normalizedIDs(_ ids: [String]) -> [String] {
    Array(
      Set(
        ids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { $0.isEmpty == false }
      )
    )
    .sorted()
  }
}
