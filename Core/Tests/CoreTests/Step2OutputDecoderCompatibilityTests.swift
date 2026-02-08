import Testing

@testable import Core

@Test func step2DecoderRemainsCompatibleWithV1Payload() throws {
  let fenced = """
    ```json
    {
      "flashcards":[{"front":"Q","back":"A","tagsRaw":"t"}],
      "todos":[{"title":"T","detail":"D","estimatedMinutes":30,"frequencyRaw":"once"}]
    }
    ```
    """

  let output = try Step2OutputDecoder.decode(fromAssistantContent: fenced)
  #expect(output.flashcards.count == 1)
  #expect(output.todos.count == 1)
  #expect(output.todos[0].statusRaw == nil)
  #expect(output.todos[0].priorityRaw == nil)
  #expect(output.todos[0].scheduledAtISO8601 == nil)
  #expect(output.todos[0].dueAtISO8601 == nil)
}

@Test func step2DecoderParsesV2OptionalSemanticFields() throws {
  let fenced = """
    ```json
    {
      "flashcards":[{"front":"Q","back":"A","tagsRaw":"t"}],
      "todos":[
        {
          "title":"T",
          "detail":"D",
          "estimatedMinutes":30,
          "frequencyRaw":"weekday",
          "statusRaw":"doing",
          "priorityRaw":"high",
          "scheduledAtISO8601":"2026-02-09T09:00:00Z",
          "dueAtISO8601":"2026-02-11T18:00:00Z"
        }
      ]
    }
    ```
    """

  let output = try Step2OutputDecoder.decode(fromAssistantContent: fenced)
  #expect(output.todos.count == 1)
  #expect(output.todos[0].statusRaw == "doing")
  #expect(output.todos[0].priorityRaw == "high")
  #expect(output.todos[0].scheduledAtISO8601 == "2026-02-09T09:00:00Z")
  #expect(output.todos[0].dueAtISO8601 == "2026-02-11T18:00:00Z")
}

@Test func step2PromptVersionUpgradedToV2() {
  #expect(Step2Pipeline.promptVersion == "step2-v2")
}
