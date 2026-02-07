import Foundation
import SwiftData

@Model
public final class TodoItem {
  @Attribute(.unique)
  public var id: UUID

  public var title: String
  public var detail: String
  public var estimatedMinutes: Int?

  public var statusRaw: String
  public var frequencyRaw: String

  public var scheduledAt: Date?
  public var dueAt: Date?

  public var createdAt: Date
  public var updatedAt: Date

  public var document: PlanDocument?

  public init(
    title: String,
    detail: String,
    estimatedMinutes: Int? = nil,
    statusRaw: String = "todo",
    frequencyRaw: String = "once",
    scheduledAt: Date? = nil,
    dueAt: Date? = nil,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.title = title
    self.detail = detail
    self.estimatedMinutes = estimatedMinutes
    self.statusRaw = statusRaw
    self.frequencyRaw = frequencyRaw
    self.scheduledAt = scheduledAt
    self.dueAt = dueAt
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
