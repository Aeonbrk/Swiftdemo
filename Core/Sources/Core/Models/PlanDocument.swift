import Foundation
import SwiftData

private enum PlanDocumentDefaults {
  static let syncOwnershipPolicy: SyncOwnershipPolicy = .localWins
  static let automationPermissionPolicy: AutomationPermissionPolicy = .assistive
}

@Model
public final class PlanDocument {
  @Attribute(.unique)
  public var id: UUID

  public var title: String
  public var rawInput: String
  public var syncOwnershipPolicyRaw: String = SyncOwnershipPolicy.localWins.rawValue
  public var automationPermissionPolicyRaw: String = AutomationPermissionPolicy.assistive.rawValue

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

  @Relationship(deleteRule: .cascade, inverse: \AutomationAuditEntry.document)
  public var automationAudits: [AutomationAuditEntry]

  public var syncOwnershipPolicy: SyncOwnershipPolicy {
    get { Self.decodeSyncOwnershipPolicy(from: syncOwnershipPolicyRaw) }
    set { syncOwnershipPolicyRaw = newValue.rawValue }
  }

  public var automationPermissionPolicy: AutomationPermissionPolicy {
    get { Self.decodeAutomationPermissionPolicy(from: automationPermissionPolicyRaw) }
    set { automationPermissionPolicyRaw = newValue.rawValue }
  }

  public init(
    title: String,
    rawInput: String,
    syncOwnershipPolicyRaw: String = SyncOwnershipPolicy.localWins.rawValue,
    automationPermissionPolicyRaw: String = AutomationPermissionPolicy.assistive.rawValue,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.title = title
    self.rawInput = rawInput
    self.syncOwnershipPolicyRaw = syncOwnershipPolicyRaw
    self.automationPermissionPolicyRaw = automationPermissionPolicyRaw
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.outline = nil
    self.todos = []
    self.flashcards = []
    self.claims = []
    self.citations = []
    self.generations = []
    self.automationAudits = []
  }

  public convenience init(
    title: String,
    rawInput: String,
    syncOwnershipPolicy: SyncOwnershipPolicy,
    automationPermissionPolicy: AutomationPermissionPolicy,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.init(
      title: title,
      rawInput: rawInput,
      syncOwnershipPolicyRaw: syncOwnershipPolicy.rawValue,
      automationPermissionPolicyRaw: automationPermissionPolicy.rawValue,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }

  private static func decodeSyncOwnershipPolicy(from raw: String) -> SyncOwnershipPolicy {
    SyncOwnershipPolicy(rawValue: raw) ?? PlanDocumentDefaults.syncOwnershipPolicy
  }

  private static func decodeAutomationPermissionPolicy(from raw: String) -> AutomationPermissionPolicy {
    AutomationPermissionPolicy(rawValue: raw) ?? PlanDocumentDefaults.automationPermissionPolicy
  }
}
