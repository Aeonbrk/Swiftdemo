import Foundation
import SwiftData

@Model
public final class PlanOutline {
  @Attribute(.unique)
  public var id: UUID

  public var planJSON: String
  public var planMarkdown: String

  public var createdAt: Date
  public var updatedAt: Date

  public var document: PlanDocument?

  public init(
    planJSON: String,
    planMarkdown: String,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.planJSON = planJSON
    self.planMarkdown = planMarkdown
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
