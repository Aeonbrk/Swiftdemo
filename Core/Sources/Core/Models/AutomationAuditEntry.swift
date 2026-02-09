import Foundation
import SwiftData

public enum AutomationPermissionPolicy: String, CaseIterable, Codable, Sendable {
  case manualOnly
  case assistive
  case fullAuto
}

public enum AutomationAuditStatus: String, CaseIterable, Codable, Sendable {
  case pending
  case success
  case blocked
}

public enum AutomationAuditAction: String, CaseIterable, Codable, Sendable {
  case recommendationAccepted = "recommendation.accepted"
  case recommendationDismissed = "recommendation.dismissed"
  case recommendationBlocked = "recommendation.blocked"
  case syncQueuedForReview = "sync.queued_for_review"
  case syncAppliedRemote = "sync.applied_remote"
  case syncKeptLocal = "sync.kept_local"
  case syncAppliedByPolicy = "sync.applied_by_policy"
}

private enum AutomationAuditEntryDefaults {
  static let action: AutomationAuditAction = .syncAppliedByPolicy
  static let status: AutomationAuditStatus = .success
}

@Model
public final class AutomationAuditEntry {
  @Attribute(.unique)
  public var id: UUID

  public var createdAt: Date
  public var actionRaw: String
  public var statusRaw: String
  public var summary: String
  public var targetTodoIDRaw: String?
  public var reviewerNote: String?

  public var document: PlanDocument?

  public var action: AutomationAuditAction {
    get { Self.decodeAction(from: actionRaw) }
    set { actionRaw = newValue.rawValue }
  }

  public var status: AutomationAuditStatus {
    get { Self.decodeStatus(from: statusRaw) }
    set { statusRaw = newValue.rawValue }
  }

  public init(
    actionRaw: String,
    statusRaw: String,
    summary: String,
    targetTodoIDRaw: String? = nil,
    reviewerNote: String? = nil,
    createdAt: Date = .now
  ) {
    self.id = UUID()
    self.createdAt = createdAt
    self.actionRaw = actionRaw
    self.statusRaw = statusRaw
    self.summary = summary
    self.targetTodoIDRaw = targetTodoIDRaw
    self.reviewerNote = reviewerNote
  }

  public convenience init(
    action: AutomationAuditAction,
    status: AutomationAuditStatus,
    summary: String,
    targetTodoIDRaw: String? = nil,
    reviewerNote: String? = nil,
    createdAt: Date = .now
  ) {
    self.init(
      actionRaw: action.rawValue,
      statusRaw: status.rawValue,
      summary: summary,
      targetTodoIDRaw: targetTodoIDRaw,
      reviewerNote: reviewerNote,
      createdAt: createdAt
    )
  }

  private static func decodeAction(from raw: String) -> AutomationAuditAction {
    AutomationAuditAction(rawValue: raw) ?? AutomationAuditEntryDefaults.action
  }

  private static func decodeStatus(from raw: String) -> AutomationAuditStatus {
    AutomationAuditStatus(rawValue: raw) ?? AutomationAuditEntryDefaults.status
  }
}
