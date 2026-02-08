import Foundation
import SwiftData
import Testing

@testable import Core

@Test func planDocumentDefaultsIncludeAutomationPermissionPolicy() {
  let document = PlanDocument(title: "Plan", rawInput: "RAW")
  #expect(document.automationPermissionPolicyRaw == AutomationPermissionPolicy.assistive.rawValue)
}

@Test @MainActor func automationAuditEntryPersistsWithDocument() throws {
  let container = try CoreModelContainer.make(inMemory: true)
  let context = ModelContext(container)

  let document = PlanDocument(title: "Plan", rawInput: "RAW")
  let entry = AutomationAuditEntry(
    actionRaw: AutomationAuditAction.syncQueuedForReview.rawValue,
    statusRaw: AutomationAuditStatus.pending.rawValue,
    summary: "Queued for manual review",
    targetTodoIDRaw: UUID().uuidString,
    reviewerNote: "Policy requires review"
  )
  entry.document = document

  context.insert(document)
  context.insert(entry)
  try context.save()

  let audits = try context.fetch(FetchDescriptor<AutomationAuditEntry>())
  #expect(audits.count == 1)
  #expect(audits[0].action == .syncQueuedForReview)
  #expect(audits[0].status == .pending)
  #expect(audits[0].summary == "Queued for manual review")
}
