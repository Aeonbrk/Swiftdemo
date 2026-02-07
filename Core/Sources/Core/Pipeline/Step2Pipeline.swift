import Foundation

public struct Step2Pipeline {
  public static let promptVersion = "step2-v1"

  private let client: OpenAICompatibleClient
  private let model: String

  public init(client: OpenAICompatibleClient, model: String) {
    self.client = client
    self.model = model
  }

  public func run(planJSON: String, planMarkdown: String) async throws -> Step2Output {
    let system = """
      You are a learning-plan assistant.
      Return exactly one JSON object (no prose) matching:
      {
        "flashcards": [{"front":"...","back":"...","tagsRaw":"tag1 tag2"}],
        "todos": [{"title":"...","detail":"...","estimatedMinutes":30,"frequencyRaw":"once"}]
      }
      """

    let user = """
      Derive flashcards and todos from this plan. Keep todos schedulable by a human (no fixed timestamps).

      PLAN_MARKDOWN:
      \(planMarkdown)

      PLAN_JSON:
      \(planJSON)
      """

    let content = try await client.createChatCompletion(
      model: model,
      messages: [
        OpenAIChatMessage(role: .system, content: system),
        OpenAIChatMessage(role: .user, content: user)
      ]
    )

    return try Step2OutputDecoder.decode(fromAssistantContent: content)
  }
}
