import SwiftData

public enum CoreModelContainer {
  enum CoreModelContainerError: Error {
    case noRegisteredModelTypes
  }

  private static let registeredModelTypes: [any PersistentModel.Type] = [
    AutomationAuditEntry.self,
    Citation.self,
    Claim.self,
    Flashcard.self,
    GenerationRecord.self,
    LLMProvider.self,
    PlanDocument.self,
    PlanOutline.self,
    TodoItem.self
  ]

  public static func make(inMemory: Bool) throws -> ModelContainer {
    guard !registeredModelTypes.isEmpty else {
      throw CoreModelContainerError.noRegisteredModelTypes
    }

    let schema = Schema(registeredModelTypes)

    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: inMemory
    )

    return try ModelContainer(
      for: schema,
      configurations: [configuration]
    )
  }
}
