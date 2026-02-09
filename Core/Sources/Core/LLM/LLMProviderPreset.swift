import Foundation

public struct LLMProviderPreset: Sendable, Hashable, Identifiable {
  public enum PresetID: String, Sendable, Hashable {
    case openAI
    case deepSeek
    case claudeOpenRouter
    case geminiOpenRouter
  }

  public var id: PresetID
  public var name: String
  public var baseURL: String
  public var model: String
  public var extraHeadersJSON: String

  public init(
    id: PresetID,
    name: String,
    baseURL: String,
    model: String,
    extraHeadersJSON: String
  ) {
    self.id = id
    self.name = name
    self.baseURL = baseURL
    self.model = model
    self.extraHeadersJSON = extraHeadersJSON
  }
}

extension LLMProviderPreset {
  public static let openAI = LLMProviderPreset(
    id: .openAI,
    name: "OpenAI",
    baseURL: "https://api.openai.com/v1",
    model: "gpt-4.1-mini",
    extraHeadersJSON: "{}"
  )

  public static let deepSeek = LLMProviderPreset(
    id: .deepSeek,
    name: "DeepSeek",
    baseURL: "https://api.deepseek.com/v1",
    model: "deepseek-chat",
    extraHeadersJSON: "{}"
  )

  public static let claudeOpenRouter = LLMProviderPreset(
    id: .claudeOpenRouter,
    name: "Claude (OpenRouter)",
    baseURL: "https://openrouter.ai/api/v1",
    model: "anthropic/claude-3.5-sonnet",
    extraHeadersJSON: openRouterExtraHeadersJSON
  )

  public static let geminiOpenRouter = LLMProviderPreset(
    id: .geminiOpenRouter,
    name: "Gemini (OpenRouter)",
    baseURL: "https://openrouter.ai/api/v1",
    model: "google/gemini-1.5-pro",
    extraHeadersJSON: openRouterExtraHeadersJSON
  )

  public static let all: [LLMProviderPreset] = [
    .openAI,
    .deepSeek,
    .claudeOpenRouter,
    .geminiOpenRouter
  ]

  private static let openRouterExtraHeadersJSON = """
    {
      "HTTP-Referer": "https://example.com",
      "X-Title": "Learning Plan"
    }
    """
}
