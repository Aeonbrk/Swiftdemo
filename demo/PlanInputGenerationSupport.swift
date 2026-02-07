import Core
import Foundation
import SwiftData

struct ProviderSnapshot: Sendable {
  var name: String
  var baseURL: String
  var model: String
  var extraHeadersJSON: String
  var apiKeyKeychainAccount: String

  init(provider: LLMProvider) {
    self.name = provider.name
    self.baseURL = provider.baseURL
    self.model = provider.model
    self.extraHeadersJSON = provider.extraHeadersJSON
    self.apiKeyKeychainAccount = provider.apiKeyKeychainAccount
  }
}

struct GenerationRequestContext {
  let providerSnapshot: ProviderSnapshot
  let baseURL: URL
  let apiKey: String
  let extraHeaders: [String: String]
}

struct GenerationRecordInput {
  let provider: ProviderSnapshot?
  let promptVersion: String
  let statusRaw: String
  let errorSummary: String?
}

func planInputGenerationErrorMessage(_ error: Error) -> String {
  let nsError = error as NSError
  if isSandboxNetworkDenied(nsError) {
    let message =
      "Generation failed: 网络请求被系统拒绝（App Sandbox 未允许 Outgoing Connections）。"
      + "请在 Xcode 的 Target -> Signing & Capabilities -> App Sandbox 勾选 "
      + "Outgoing Connections (Client)，然后重新运行。"
    return message
  }
  return "Generation failed: \(error)"
}

func parseProviderExtraHeadersJSON(_ json: String) throws -> [String: String] {
  let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty { return [:] }

  guard let data = trimmed.data(using: .utf8) else { return [:] }
  let object = try JSONSerialization.jsonObject(with: data, options: [])
  guard let dict = object as? [String: Any] else { return [:] }

  var headers: [String: String] = [:]
  for (key, value) in dict {
    headers[key] = String(describing: value)
  }
  return headers
}

func applyStep1Output(
  _ output: Step1Output, to document: PlanDocument, in modelContext: ModelContext
) {
  if let outline = document.outline {
    document.outline = nil
    modelContext.delete(outline)
  }

  let oldClaims = document.claims
  document.claims.removeAll()
  for claim in oldClaims { modelContext.delete(claim) }

  let oldCitations = document.citations
  document.citations.removeAll()
  for citation in oldCitations { modelContext.delete(citation) }

  let outline = PlanOutline(planJSON: output.planJSON, planMarkdown: output.planMarkdown)
  outline.document = document
  document.outline = outline

  var citationByID: [String: Citation] = [:]
  for item in output.citations {
    let citation = Citation(url: item.url, title: item.title, quotedText: item.quotedText)
    citation.document = document
    modelContext.insert(citation)
    citationByID[item.id] = citation
  }

  for item in output.claims {
    let claim = Claim(text: item.text, importance: item.importance)
    claim.document = document
    modelContext.insert(claim)

    for citationID in item.citationIDs {
      if let citation = citationByID[citationID] {
        claim.citations.append(citation)
      }
    }
  }
}

func applyStep2Output(
  _ output: Step2Output,
  to document: PlanDocument,
  in modelContext: ModelContext
) -> (selectedCardID: UUID?, selectedTodoID: UUID?) {
  let oldCards = document.flashcards
  document.flashcards.removeAll()
  for card in oldCards { modelContext.delete(card) }

  let oldTodos = document.todos
  document.todos.removeAll()
  for todo in oldTodos { modelContext.delete(todo) }

  for item in output.flashcards {
    let card = Flashcard(front: item.front, back: item.back, tagsRaw: item.tagsRaw)
    card.document = document
    modelContext.insert(card)
  }

  for item in output.todos {
    let todo = TodoItem(
      title: item.title,
      detail: item.detail,
      estimatedMinutes: item.estimatedMinutes,
      statusRaw: "todo",
      frequencyRaw: item.frequencyRaw
    )
    todo.document = document
    modelContext.insert(todo)
  }

  return (document.flashcards.first?.id, document.todos.first?.id)
}

func appendGenerationRecord(
  _ input: GenerationRecordInput,
  document: PlanDocument,
  in modelContext: ModelContext
) {
  let record = GenerationRecord(
    providerName: input.provider?.name ?? "Unknown",
    baseURL: input.provider?.baseURL ?? "",
    model: input.provider?.model ?? "",
    promptVersion: input.promptVersion,
    statusRaw: input.statusRaw,
    inputSummary: String(document.rawInput.prefix(200)),
    outputSummary: document.outline.map { String($0.planMarkdown.prefix(200)) },
    errorSummary: input.errorSummary,
    errorDetails: nil
  )
  record.document = document
  modelContext.insert(record)
}

private func isSandboxNetworkDenied(_ error: NSError) -> Bool {
  if error.domain == NSPOSIXErrorDomain, error.code == 1 {
    return true
  }

  if error.domain == NSURLErrorDomain,
    let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError,
    underlying.domain == NSPOSIXErrorDomain,
    underlying.code == 1 {
    return true
  }

  return false
}
