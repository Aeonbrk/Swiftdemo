import Foundation
import SwiftData
import Testing

@testable import Core

@Test @MainActor func planDocumentPersistsInMemory() throws {
  let context = try makeInMemoryContext()

  let document = PlanDocument(title: "Rust 90 Days", rawInput: "RAW")
  context.insert(document)
  try context.save()

  let persistedDocuments = try context.fetch(FetchDescriptor<PlanDocument>())
  #expect(persistedDocuments.count == 1)
  #expect(persistedDocuments[0].title == "Rust 90 Days")
  #expect(persistedDocuments[0].rawInput == "RAW")
}

@Test @MainActor func todoItemPersistsWithTimestamps() throws {
  let context = try makeInMemoryContext()

  let document = PlanDocument(title: "Plan", rawInput: "RAW")
  let todo = TodoItem(
    title: "Read Chapter 1",
    detail: "Ownership basics",
    estimatedMinutes: 45
  )
  todo.document = document
  todo.dueAt = Date(timeIntervalSince1970: 123)

  context.insert(document)
  context.insert(todo)
  try context.save()

  let persistedTodos = try context.fetch(FetchDescriptor<TodoItem>())
  #expect(persistedTodos.count == 1)
  #expect(persistedTodos[0].title == "Read Chapter 1")
  #expect(persistedTodos[0].dueAt != nil)
  #expect(persistedTodos[0].document?.id == document.id)

  let persistedDocuments = try context.fetch(FetchDescriptor<PlanDocument>())
  #expect(persistedDocuments.count == 1)
  #expect(persistedDocuments[0].todos.count == 1)
}

@Test @MainActor func outlineCardsClaimsCitationsPersist() throws {
  let context = try makeInMemoryContext()

  let document = PlanDocument(title: "Plan", rawInput: "RAW")
  document.outline = PlanOutline(planJSON: "{}", planMarkdown: "# Plan")

  let card = Flashcard(front: "Q", back: "A", tagsRaw: "rust ownership")
  card.document = document

  let claim = Claim(text: "Rust stable releases about every 6 weeks.", importance: 1)
  claim.document = document

  let citation = Citation(url: "https://example.com")
  citation.claim = claim
  citation.document = document

  context.insert(document)
  context.insert(card)
  context.insert(claim)
  context.insert(citation)
  try context.save()

  let fetchedCards = try context.fetch(FetchDescriptor<Flashcard>())
  #expect(fetchedCards.count == 1)
  #expect(fetchedCards[0].document?.id == document.id)

  let fetchedCitations = try context.fetch(FetchDescriptor<Citation>())
  #expect(fetchedCitations.count == 1)
  #expect(fetchedCitations[0].verificationStatusRaw == "unverified")
  #expect(fetchedCitations[0].claim?.id == claim.id)
}

@Test @MainActor func generationRecordPersists() throws {
  let context = try makeInMemoryContext()

  let document = PlanDocument(title: "Plan", rawInput: "RAW")
  let record = GenerationRecord(
    providerName: "DeepSeek",
    baseURL: "https://api.example.com/v1",
    model: "deepseek-chat",
    promptVersion: "v1",
    statusRaw: "failed",
    errorSummary: "401 Unauthorized"
  )
  record.document = document

  context.insert(document)
  context.insert(record)
  try context.save()

  let persistedRecords = try context.fetch(FetchDescriptor<GenerationRecord>())
  #expect(persistedRecords.count == 1)
  #expect(persistedRecords[0].providerName == "DeepSeek")
  #expect(persistedRecords[0].statusRaw == "failed")

  let persistedDocuments = try context.fetch(FetchDescriptor<PlanDocument>())
  #expect(persistedDocuments.count == 1)
  #expect(persistedDocuments[0].generations.count == 1)
}

@Test @MainActor func providerConfigPersists() throws {
  let context = try makeInMemoryContext()

  let provider = LLMProvider(
    name: "DeepSeek",
    baseURL: "https://api.deepseek.com/v1",
    model: "deepseek-chat",
    extraHeadersJSON: "{\"X-Test\":\"1\"}",
    apiKeyKeychainAccount: "provider-1"
  )

  context.insert(provider)
  try context.save()

  let persistedProviders = try context.fetch(FetchDescriptor<LLMProvider>())
  #expect(persistedProviders.count == 1)
  #expect(persistedProviders[0].name == "DeepSeek")
  #expect(persistedProviders[0].baseURL == "https://api.deepseek.com/v1")
  #expect(persistedProviders[0].model == "deepseek-chat")
  #expect(persistedProviders[0].apiKeyKeychainAccount == "provider-1")
}

@Test func openAICompatibleClientSendsBearerToken() async throws {
  let assistantContent =
    "{\"planJSON\":\"{}\",\"planMarkdown\":\"# Plan\",\"claims\":[],\"citations\":[]}"
  let chatCompletionResponseData = try makeChatCompletionResponseData(
    completionID: "cmpl-1",
    assistantContent: assistantContent
  )

  MockURLProtocol.setHandler(path: "/v1/test-openai-client/chat/completions") { request in
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    return (
      HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
      chatCompletionResponseData
    )
  }

  let client = makeMockClient(testPath: "test-openai-client")

  let content = try await client.createChatCompletion(
    model: "test-model",
    messages: [
      .init(role: .user, content: "hi")
    ]
  )

  #expect(content == assistantContent)
}

@Test func step1DecoderExtractsJSONFromCodeFence() throws {
  let fenced = """
    Here is the result:
    ```json
    {\"planJSON\":\"{}\",\"planMarkdown\":\"# Plan\",\"claims\":[],\"citations\":[]}
    ```
    """

  let output = try Step1OutputDecoder.decode(fromAssistantContent: fenced)
  #expect(output.planJSON == "{}")
  #expect(output.planMarkdown == "# Plan")
}

@Test func step1PipelineCallsClientAndDecodes() async throws {
  let assistantContent = """
    ```json
    {\"planJSON\":\"{}\",\"planMarkdown\":\"# Plan\",\"claims\":[],\"citations\":[]}
    ```
    """
  let chatCompletionResponseData = try makeChatCompletionResponseData(
    completionID: "cmpl-1",
    assistantContent: assistantContent
  )

  MockURLProtocol.setHandler(path: "/v1/test-step1/chat/completions") { request in
    return (
      HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
      chatCompletionResponseData
    )
  }

  let client = makeMockClient(testPath: "test-step1")

  let pipeline = Step1Pipeline(client: client, model: "test-model")
  let output = try await pipeline.run(rawInput: "RAW")

  #expect(output.planMarkdown == "# Plan")
}

@Test func step2DecoderExtractsJSONFromCodeFence() throws {
  let fenced = """
    ```json
    {"flashcards":[{"front":"Q","back":"A","tagsRaw":"t"}],
    "todos":[{"title":"T","detail":"D","estimatedMinutes":30,"frequencyRaw":"once"}]}
    ```
    """

  let output = try Step2OutputDecoder.decode(fromAssistantContent: fenced)
  #expect(output.flashcards.count == 1)
  #expect(output.todos.count == 1)
}

@Test func step2PipelineCallsClientAndDecodes() async throws {
  let assistantContent = """
    ```json
    {"flashcards":[{"front":"Q","back":"A","tagsRaw":"t"}],
    "todos":[{"title":"T","detail":"D","estimatedMinutes":30,"frequencyRaw":"once"}]}
    ```
    """
  let chatCompletionResponseData = try makeChatCompletionResponseData(
    completionID: "cmpl-2",
    assistantContent: assistantContent
  )

  MockURLProtocol.setHandler(path: "/v1/test-step2/chat/completions") { request in
    return (
      HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
      chatCompletionResponseData
    )
  }

  let client = makeMockClient(testPath: "test-step2")

  let pipeline = Step2Pipeline(client: client, model: "test-model")
  let output = try await pipeline.run(planJSON: "{}", planMarkdown: "#")
  #expect(output.flashcards.count == 1)
  #expect(output.todos.count == 1)
}

@Test func flashcardsTSVExportEscapesTabsAndNewlines() throws {
  let card = Flashcard(front: "a\tb", back: "c\nd", tagsRaw: "t")
  let tsv = FlashcardsExporter.tsv(cards: [card])
  #expect(tsv == "a b\tc<br>d\tt\n")
}

@Test func flashcardsCSVQuotesAndEscapes() throws {
  let card = Flashcard(front: "a, \"b\"", back: "line1\nline2", tagsRaw: "t")
  let csv = FlashcardsExporter.csv(cards: [card])
  #expect(csv == "\"a, \"\"b\"\"\",line1<br>line2,t\n")
}

@Test func todosCSVQuotesAndEscapes() throws {
  let todo = TodoItem(title: "a, \"b\"", detail: "line1\nline2", estimatedMinutes: 30)
  let csv = TodosExporter.csv(todos: [todo])
  let expectedCSV =
    "Title,Detail,EstimatedMinutes,Frequency,Status,ScheduledAt,DueAt\n"
    + "\"a, \"\"b\"\"\",line1<br>line2,30,once,todo,,\n"
  #expect(
    csv == expectedCSV
  )
}

@Test func providerPresetsIncludeFourDefaults() {
  let presets = LLMProviderPreset.all
  #expect(presets.count == 4)
  #expect(presets.contains(where: { $0.id == .openAI }))
  #expect(presets.contains(where: { $0.id == .deepSeek }))

  for preset in presets {
    #expect(preset.name.isEmpty == false)
    #expect(preset.baseURL.hasPrefix("https://"))
    #expect(preset.baseURL.contains("/v1"))
    #expect(preset.model.isEmpty == false)
    #expect(preset.extraHeadersJSON.isEmpty == false)
  }
}

@MainActor
private func makeInMemoryContext() throws -> ModelContext {
  let container = try CoreModelContainer.make(inMemory: true)
  return ModelContext(container)
}

private func makeChatCompletionResponseData(
  completionID: String,
  assistantContent: String
) throws -> Data {
  try JSONSerialization.data(
    withJSONObject: [
      "id": completionID,
      "choices": [
        [
          "index": 0,
          "message": [
            "role": "assistant",
            "content": assistantContent
          ]
        ]
      ]
    ],
    options: []
  )
}

private func makeMockClient(
  testPath: String,
  apiKey: String = "test-key"
) -> OpenAICompatibleClient {
  OpenAICompatibleClient(
    baseURL: URL(string: "https://api.example.com/v1/\(testPath)")!,
    apiKey: apiKey,
    urlSession: makeMockSession()
  )
}

private func makeMockSession() -> URLSession {
  let configuration = URLSessionConfiguration.ephemeral
  configuration.protocolClasses = [MockURLProtocol.self]
  return URLSession(configuration: configuration)
}

private final class MockURLProtocol: URLProtocol {
  nonisolated(unsafe) private static var handlers:
    [String: (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]
  private static let lock = NSLock()

  static func setHandler(
    path: String,
    handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
  ) {
    lock.lock()
    handlers[path] = handler
    lock.unlock()
  }

  // swiftlint:disable:next static_over_final_class
  override class func canInit(with request: URLRequest) -> Bool { true }
  // swiftlint:disable:next static_over_final_class
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let (response, data) = try Self.response(for: request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}

  private static func response(for request: URLRequest) throws -> (HTTPURLResponse, Data) {
    guard let path = request.url?.path else {
      throw URLError(.badURL)
    }

    lock.lock()
    let handler = handlers[path]
    lock.unlock()

    guard let handler else {
      throw URLError(.badServerResponse)
    }

    return try handler(request)
  }
}
