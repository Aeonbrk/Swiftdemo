import Foundation
import SwiftData

@Model
public final class Flashcard {
  @Attribute(.unique)
  public var id: UUID

  public var front: String
  public var back: String
  public var tagsRaw: String

  // swiftlint:disable:next inclusive_language
  public var masteryRaw: String
  public var dueAt: Date?

  public var createdAt: Date
  public var updatedAt: Date

  public var document: PlanDocument?

  public init(
    front: String,
    back: String,
    tagsRaw: String = "",
    // swiftlint:disable:next inclusive_language
    masteryRaw: String = "new",
    dueAt: Date? = nil,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.front = front
    self.back = back
    self.tagsRaw = tagsRaw
    self.masteryRaw = masteryRaw
    self.dueAt = dueAt
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
