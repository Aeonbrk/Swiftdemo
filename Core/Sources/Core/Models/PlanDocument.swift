import Foundation
import SwiftData

@Model
public final class PlanDocument {
  @Attribute(.unique)
  public var id: UUID

  public var title: String
  public var rawInput: String

  public var createdAt: Date
  public var updatedAt: Date

  @Relationship(deleteRule: .cascade, inverse: \PlanOutline.document)
  public var outline: PlanOutline?

  @Relationship(deleteRule: .cascade, inverse: \TodoItem.document)
  public var todos: [TodoItem]

  @Relationship(deleteRule: .cascade, inverse: \Flashcard.document)
  public var flashcards: [Flashcard]

  @Relationship(deleteRule: .cascade, inverse: \Claim.document)
  public var claims: [Claim]

  @Relationship(deleteRule: .cascade, inverse: \Citation.document)
  public var citations: [Citation]

  @Relationship(deleteRule: .cascade, inverse: \GenerationRecord.document)
  public var generations: [GenerationRecord]

  public init(
    title: String,
    rawInput: String,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.title = title
    self.rawInput = rawInput
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.outline = nil
    self.todos = []
    self.flashcards = []
    self.claims = []
    self.citations = []
    self.generations = []
  }
}
