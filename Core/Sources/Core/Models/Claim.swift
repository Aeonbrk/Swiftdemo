import Foundation
import SwiftData

@Model
public final class Claim {
  @Attribute(.unique)
  public var id: UUID

  public var text: String
  public var importance: Int?

  public var createdAt: Date
  public var updatedAt: Date

  public var document: PlanDocument?

  @Relationship(deleteRule: .cascade, inverse: \Citation.claim)
  public var citations: [Citation]

  public init(
    text: String,
    importance: Int? = nil,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.text = text
    self.importance = importance
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.citations = []
  }
}
