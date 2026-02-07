import Foundation

public struct OpenAICompatibleClient {
  public struct HTTPError: Error {
    public var statusCode: Int
    public var body: String

    public init(statusCode: Int, body: String) {
      self.statusCode = statusCode
      self.body = body
    }
  }

  private let baseURL: URL
  private let apiKey: String
  private let urlSession: URLSession
  private let extraHeaders: [String: String]

  public init(
    baseURL: URL,
    apiKey: String,
    urlSession: URLSession = .shared,
    extraHeaders: [String: String] = [:]
  ) {
    self.baseURL = baseURL
    self.apiKey = apiKey
    self.urlSession = urlSession
    self.extraHeaders = extraHeaders
  }

  public func createChatCompletion(
    model: String,
    messages: [OpenAIChatMessage]
  ) async throws -> String {
    let endpoint = baseURL.appendingPathComponent("chat/completions")

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    for (key, value) in extraHeaders {
      request.setValue(value, forHTTPHeaderField: key)
    }

    let payload = ChatCompletionsRequest(model: model, messages: messages)
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    if (200..<300).contains(http.statusCode) == false {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw HTTPError(statusCode: http.statusCode, body: body)
    }

    let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
    guard let content = decoded.choices.first?.message.content, content.isEmpty == false else {
      throw URLError(.cannotParseResponse)
    }
    return content
  }
}

private struct ChatCompletionsRequest: Encodable {
  let model: String
  let messages: [OpenAIChatMessage]
}

private struct ChatCompletionsResponse: Decodable {
  struct Choice: Decodable {
    let message: ChatCompletionsMessage
  }

  let choices: [Choice]
}

private struct ChatCompletionsMessage: Decodable {
  let content: String
}
