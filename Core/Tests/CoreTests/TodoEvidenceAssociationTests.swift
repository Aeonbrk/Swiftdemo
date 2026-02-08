import SwiftData
import Testing

@testable import Core

@Test func todoEvidenceIDsAreNormalizedAndDeduplicated() {
  let todo = TodoItem(
    title: "Task",
    detail: "Detail",
    estimatedMinutes: 20,
    frequencyRaw: "once"
  )

  todo.linkedClaimIDs = ["claim-b", "claim-a", "claim-a", " "]
  todo.linkedCitationIDs = ["cite-2", "cite-1", "cite-2"]

  #expect(todo.linkedClaimIDs == ["claim-a", "claim-b"])
  #expect(todo.linkedCitationIDs == ["cite-1", "cite-2"])
  #expect(todo.linkedClaimIDsRaw == "claim-a,claim-b")
  #expect(todo.linkedCitationIDsRaw == "cite-1,cite-2")
}

@Test @MainActor func todoEvidenceIDsPersistWithDocument() throws {
  let container = try CoreModelContainer.make(inMemory: true)
  let context = ModelContext(container)

  let document = PlanDocument(title: "Plan", rawInput: "RAW")
  let todo = TodoItem(
    title: "Task",
    detail: "Detail",
    estimatedMinutes: 20,
    frequencyRaw: "once"
  )
  todo.linkedClaimIDs = ["claim-1", "claim-2"]
  todo.linkedCitationIDs = ["cite-1"]
  todo.document = document

  context.insert(document)
  context.insert(todo)
  try context.save()

  let fetched = try context.fetch(FetchDescriptor<TodoItem>())
  #expect(fetched.count == 1)
  #expect(fetched[0].linkedClaimIDs == ["claim-1", "claim-2"])
  #expect(fetched[0].linkedCitationIDs == ["cite-1"])
}
