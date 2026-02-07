import SwiftData

public enum CoreModelContainer {
  public static func make(inMemory: Bool) throws -> ModelContainer {
    let schema = Schema([
      PlanDocument.self,
      PlanOutline.self,
      TodoItem.self,
      Flashcard.self,
      Claim.self,
      Citation.self,
      GenerationRecord.self,
      LLMProvider.self
    ])

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
