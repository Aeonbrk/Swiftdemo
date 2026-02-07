import Foundation

public struct Step1Pipeline {
  public static let promptVersion = "step1-v1"

  private let client: OpenAICompatibleClient
  private let model: String

  public init(client: OpenAICompatibleClient, model: String) {
    self.client = client
    self.model = model
  }

  public func run(rawInput: String) async throws -> Step1Output {
    let system = """
      You are a learning-plan assistant.
      Return exactly one JSON object (no prose) matching:
      {
        "planJSON": "<stringified JSON>",
        "planMarkdown": "<markdown>",
        "claims": [{"id":"c1","text":"...","importance":1,"citationIDs":["s1"]}],
        "citations": [{"id":"s1","url":"https://...","title":"...","quotedText":"..."}]
      }
      """

    let user = """
      Convert the following learning plan into a structured plan + flashcard-ready claims.
      Ensure all key claims include citations with URLs.

      INPUT:
      \(rawInput)
      """

    let content = try await client.createChatCompletion(
      model: model,
      messages: [
        OpenAIChatMessage(role: .system, content: system),
        OpenAIChatMessage(role: .user, content: user)
      ]
    )

    return try Step1OutputDecoder.decode(fromAssistantContent: content)
  }
}
