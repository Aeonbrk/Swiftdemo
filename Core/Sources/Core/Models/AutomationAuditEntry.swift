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
    get { AutomationAuditAction(rawValue: actionRaw) ?? .syncAppliedByPolicy }
    set { actionRaw = newValue.rawValue }
  }

  public var status: AutomationAuditStatus {
    get { AutomationAuditStatus(rawValue: statusRaw) ?? .success }
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
}
