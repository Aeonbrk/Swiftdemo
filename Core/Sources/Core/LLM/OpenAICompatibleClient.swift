import Foundation

public struct OpenAICompatibleClient {
  public struct HTTPError: Error {
    public let statusCode: Int
    public let body: String

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
    let request = try makeChatCompletionsRequest(model: model, messages: messages)

    let (data, response) = try await urlSession.data(for: request)
    try validate(response: response, data: data)
    return try decodeAssistantContent(from: data)
  }

  private func makeChatCompletionsRequest(
    model: String,
    messages: [OpenAIChatMessage]
  ) throws -> URLRequest {
    let endpoint = baseURL.appendingPathComponent(Endpoint.chatCompletions)
    var request = URLRequest(url: endpoint)
    request.httpMethod = HTTPMethod.post
    request.setValue(ContentType.json, forHTTPHeaderField: HeaderField.contentType)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: HeaderField.authorization)

    for (key, value) in extraHeaders {
      request.setValue(value, forHTTPHeaderField: key)
    }

    request.httpBody = try JSONEncoder().encode(
      ChatCompletionsRequest(model: model, messages: messages)
    )
    return request
  }

  private func validate(response: URLResponse, data: Data) throws {
    guard let http = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    guard (200..<300).contains(http.statusCode) else {
      let body = String(bytes: data, encoding: .utf8) ?? ""
      throw HTTPError(statusCode: http.statusCode, body: body)
    }
  }

  private func decodeAssistantContent(from data: Data) throws -> String {
    let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
    guard let content = decoded.choices.first?.message.content, content.isEmpty == false else {
      throw URLError(.cannotParseResponse)
    }
    return content
  }
}

private enum Endpoint {
  static let chatCompletions = "chat/completions"
}

private enum HTTPMethod {
  static let post = "POST"
}

private enum HeaderField {
  static let contentType = "Content-Type"
  static let authorization = "Authorization"
}

private enum ContentType {
  static let json = "application/json"
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
