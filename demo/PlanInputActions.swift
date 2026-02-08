import Core
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

#if canImport(AppKit)
  import AppKit
#endif

extension PlanInputView {
  func stringBinding<T: AnyObject>(
    for object: T,
    keyPath: ReferenceWritableKeyPath<T, String>
  ) -> Binding<String> {
    Binding(
      get: { object[keyPath: keyPath] },
      set: { newValue in
        object[keyPath: keyPath] = newValue
        markItemUpdatedIfNeeded(object)
        document.updatedAt = .now
      }
    )
  }
  func dateBinding<T: AnyObject>(
    for object: T,
    keyPath: ReferenceWritableKeyPath<T, Date?>
  ) -> Binding<Date> {
    Binding(
      get: { object[keyPath: keyPath] ?? .now },
      set: { newValue in
        object[keyPath: keyPath] = newValue
        markItemUpdatedIfNeeded(object)
        document.updatedAt = .now
      }
    )
  }
  func createFlashcard() {
    let card = Flashcard(front: "", back: "", tagsRaw: "")
    card.document = document
    modelContext.insert(card)
    selectedCardID = card.id
    document.updatedAt = .now
  }
  func deleteSelectedFlashcard() {
    guard let selectedCard else { return }
    modelContext.delete(selectedCard)
    selectedCardID = document.flashcards.first(where: { $0.id != selectedCard.id })?.id
    document.updatedAt = .now
  }
  func deleteFlashcards(at offsets: IndexSet) {
    let sorted = document.flashcards.sorted(by: { $0.createdAt > $1.createdAt })
    for index in offsets {
      modelContext.delete(sorted[index])
    }

    if let selectedCardID,
      document.flashcards.contains(where: { $0.id == selectedCardID }) == false {
      self.selectedCardID = document.flashcards.first?.id
    }
    document.updatedAt = .now
  }
  func exportFlashcardsTSV() {
    let content = FlashcardsExporter.tsv(cards: document.flashcards)
    exportTextFile(
      content: content,
      suggestedFileName: "\(document.title)-cards.tsv",
      contentType: .tabSeparatedText
    )
  }
  func exportFlashcardsCSV() {
    let content = FlashcardsExporter.csv(cards: document.flashcards)
    exportTextFile(
      content: content,
      suggestedFileName: "\(document.title)-cards.csv",
      contentType: .commaSeparatedText
    )
  }
  func createTodo() {
    let todo = TodoItem(
      title: "",
      detail: "",
      estimatedMinutes: nil,
      statusRaw: TodoStatus.todo.rawValue,
      priorityRaw: TodoPriority.medium.rawValue,
      frequencyRaw: "once"
    )
    todo.document = document
    modelContext.insert(todo)
    selectedTodoID = todo.id
    document.updatedAt = .now
  }
  func deleteSelectedTodo() {
    guard let selectedTodo else { return }
    modelContext.delete(selectedTodo)
    selectedTodoID = document.todos.first(where: { $0.id != selectedTodo.id })?.id
    document.updatedAt = .now
  }
  func deleteTodos(at offsets: IndexSet) {
    let sorted = document.todos.sorted(by: { $0.createdAt > $1.createdAt })
    for index in offsets {
      modelContext.delete(sorted[index])
    }

    if let selectedTodoID,
      document.todos.contains(where: { $0.id == selectedTodoID }) == false {
      self.selectedTodoID = document.todos.first?.id
    }
    document.updatedAt = .now
  }
  func setTodoStatus(_ todo: TodoItem, to status: TodoStatus) {
    todo.status = status
    todo.completedAt = status == .done ? (todo.completedAt ?? .now) : nil
    todo.updatedAt = .now
    document.updatedAt = .now
  }
  func exportTodosCSV() {
    let sorted = document.todos.sorted(by: { $0.createdAt < $1.createdAt })
    let content = TodosExporter.csv(todos: sorted)
    exportTextFile(
      content: content,
      suggestedFileName: "\(document.title)-todos.csv",
      contentType: .commaSeparatedText
    )
  }
  func exportTodosExtendedCSV() {
    let sorted = document.todos.sorted(by: { $0.createdAt < $1.createdAt })
    let content = TodosExporter.csvExtended(todos: sorted)
    exportTextFile(
      content: content,
      suggestedFileName: "\(document.title)-todos-extended.csv",
      contentType: .commaSeparatedText
    )
  }
  func generateStep1() {
    beginGeneration()
    let rawInput = document.rawInput
    guard let context = prepareRequestContext(promptVersion: Step1Pipeline.promptVersion) else {
      return
    }
    executeGenerationTask(
      promptVersion: Step1Pipeline.promptVersion,
      provider: context.providerSnapshot
    ) {
      let output = try await runStep1Pipeline(rawInput: rawInput, context: context)
      await MainActor.run {
        applyStep1Output(output, to: document, in: modelContext)
        finishGenerationSuccess(
          promptVersion: Step1Pipeline.promptVersion,
          provider: context.providerSnapshot,
          successMessage: "已生成 Step 1 输出。"
        )
      }
    }
  }
  func generateStep2() {
    beginGeneration()
    guard let outline = requireStep2Outline() else { return }
    guard let context = prepareRequestContext(promptVersion: Step2Pipeline.promptVersion) else {
      return
    }
    executeGenerationTask(
      promptVersion: Step2Pipeline.promptVersion,
      provider: context.providerSnapshot
    ) {
      let output = try await runStep2Pipeline(outline: outline, context: context)
      await MainActor.run {
        let selection = applyStep2Output(output, to: document, in: modelContext, mergeMode: step2MergeMode)
        selectedCardID = selection.selectedCardID
        selectedTodoID = selection.selectedTodoID
        finishGenerationSuccess(
          promptVersion: Step2Pipeline.promptVersion,
          provider: context.providerSnapshot,
          successMessage: "已生成 Step 2 输出。"
        )
      }
    }
  }
  func fetchActiveProvider() throws -> LLMProvider? {
    let descriptor = FetchDescriptor<LLMProvider>(predicate: #Predicate { $0.isActive == true })
    return try modelContext.fetch(descriptor).first
  }
  private func markItemUpdatedIfNeeded<T: AnyObject>(_ object: T) {
    if let card = object as? Flashcard {
      card.updatedAt = .now
      return
    }

    if let todo = object as? TodoItem {
      todo.updatedAt = .now
    }
  }
  private func exportTextFile(content: String, suggestedFileName: String, contentType: UTType) {
    #if canImport(AppKit)
      let panel = NSSavePanel()
      panel.allowedContentTypes = [contentType]
      panel.canCreateDirectories = true
      panel.isExtensionHidden = false
      panel.nameFieldStringValue = suggestedFileName

      let response = panel.runModal()
      guard response == .OK, let url = panel.url else { return }

      do {
        try content.write(to: url, atomically: true, encoding: .utf8)
        message = "Exported \(url.lastPathComponent)."
        errorMessage = nil
      } catch {
        errorMessage = "Export failed: \(error)"
      }
    #else
      errorMessage = "Export is only supported on macOS."
    #endif
  }
  private func runStep1Pipeline(rawInput: String, context: GenerationRequestContext) async throws
    -> Step1Output {
    let client = makeClient(context: context)
    let pipeline = Step1Pipeline(client: client, model: context.providerSnapshot.model)
    return try await pipeline.run(rawInput: rawInput)
  }
  private func runStep2Pipeline(outline: PlanOutline, context: GenerationRequestContext) async throws
    -> Step2Output {
    let client = makeClient(context: context)
    let pipeline = Step2Pipeline(client: client, model: context.providerSnapshot.model)
    return try await pipeline.run(planJSON: outline.planJSON, planMarkdown: outline.planMarkdown)
  }
  private func makeClient(context: GenerationRequestContext) -> OpenAICompatibleClient {
    OpenAICompatibleClient(
      baseURL: context.baseURL,
      apiKey: context.apiKey,
      extraHeaders: context.extraHeaders
    )
  }
  private func executeGenerationTask(
    promptVersion: String,
    provider: ProviderSnapshot,
    action: @escaping () async throws -> Void
  ) {
    Task {
      do {
        try await action()
      } catch {
        await MainActor.run {
          failGeneration(
            promptVersion: promptVersion,
            provider: provider,
            message: planInputGenerationErrorMessage(error)
          )
        }
      }
    }
  }
  private func beginGeneration() {
    errorMessage = nil
    message = nil
    isGenerating = true
  }
  private func failGeneration(promptVersion: String, provider: ProviderSnapshot?, message: String) {
    errorMessage = message
    let input = GenerationRecordInput(
      provider: provider,
      promptVersion: promptVersion,
      statusRaw: "failed",
      errorSummary: message
    )
    appendGenerationRecord(input, document: document, in: modelContext)
    isGenerating = false
  }
  private func finishGenerationSuccess(
    promptVersion: String,
    provider: ProviderSnapshot,
    successMessage: String
  ) {
    let input = GenerationRecordInput(
      provider: provider,
      promptVersion: promptVersion,
      statusRaw: "success",
      errorSummary: nil
    )
    appendGenerationRecord(input, document: document, in: modelContext)

    document.updatedAt = .now
    do {
      try modelContext.save()
    } catch {
      errorMessage = "Failed to save: \(error)"
    }

    message = successMessage
    isGenerating = false
  }
  private func prepareRequestContext(promptVersion: String) -> GenerationRequestContext? {
    guard let providerSnapshot = loadProviderSnapshot(promptVersion: promptVersion) else {
      return nil
    }

    guard let baseURL = validateBaseURL(providerSnapshot, promptVersion: promptVersion) else {
      return nil
    }

    guard let apiKey = loadAPIKey(providerSnapshot, promptVersion: promptVersion) else {
      return nil
    }

    guard let extraHeaders = loadExtraHeaders(providerSnapshot, promptVersion: promptVersion) else {
      return nil
    }

    return GenerationRequestContext(
      providerSnapshot: providerSnapshot,
      baseURL: baseURL,
      apiKey: apiKey,
      extraHeaders: extraHeaders
    )
  }
  private func requireStep2Outline() -> PlanOutline? {
    guard let outline = document.outline else {
      failGeneration(
        promptVersion: Step2Pipeline.promptVersion,
        provider: nil,
        message: "请先运行 Step 1。"
      )
      return nil
    }
    return outline
  }
  private func loadProviderSnapshot(promptVersion: String) -> ProviderSnapshot? {
    do {
      guard let provider = try fetchActiveProvider() else {
        failGeneration(
          promptVersion: promptVersion,
          provider: nil,
          message: "没有激活的 Provider，请先在 Provider 设置中配置。"
        )
        return nil
      }
      return ProviderSnapshot(provider: provider)
    } catch {
      failGeneration(
        promptVersion: promptVersion,
        provider: nil,
        message: "加载 Provider 失败：\(error)"
      )
      return nil
    }
  }
  private func validateBaseURL(_ provider: ProviderSnapshot, promptVersion: String) -> URL? {
    guard let baseURL = URL(string: provider.baseURL) else {
      failGeneration(
        promptVersion: promptVersion,
        provider: provider,
        message: "Base URL 无效：\(provider.baseURL)"
      )
      return nil
    }

    return baseURL
  }
  private func loadAPIKey(_ provider: ProviderSnapshot, promptVersion: String) -> String? {
    do {
      let apiKey = try KeychainStore.getPassword(
        service: KeychainStore.llmService,
        account: provider.apiKeyKeychainAccount
      ) ?? ""

      guard apiKey.isEmpty == false else {
          failGeneration(
            promptVersion: promptVersion,
            provider: provider,
            message: "Provider '\(provider.name)' 缺少 API Key，请先在 Provider 设置中保存。"
          )
        return nil
      }

      return apiKey
    } catch {
        failGeneration(
          promptVersion: promptVersion,
          provider: provider,
          message: "读取 API Key 失败：\(error)"
        )
      return nil
    }
  }
  private func loadExtraHeaders(_ provider: ProviderSnapshot, promptVersion: String)
    -> [String: String]? {
    do {
      return try parseProviderExtraHeadersJSON(provider.extraHeadersJSON)
    } catch {
      failGeneration(
        promptVersion: promptVersion,
        provider: provider,
        message: "extraHeadersJSON 格式错误：\(error)"
      )
      return nil
    }
  }
}
