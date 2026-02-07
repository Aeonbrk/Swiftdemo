import Core
import SwiftData
import SwiftUI

struct PlanInputView: View {
  @Environment(\.modelContext) var modelContext
  #if os(macOS)
    @Environment(\.openSettings) var openSettings
  #endif

  @Bindable var document: PlanDocument

  @State var isGenerating = false
  @State var message: String?
  @State var errorMessage: String?
  @State var selectedCardID: UUID?
  @State var selectedTodoID: UUID?
  @State var isShowingCardBack = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      headerBar
      generationStatusView
      mainTabs
    }
    .padding()
    .navigationTitle(document.title)
    .onChange(of: document.title) { _, _ in document.updatedAt = .now }
    .onChange(of: document.rawInput) { _, _ in document.updatedAt = .now }
    .onChange(of: selectedCardID) { _, _ in isShowingCardBack = false }
  }

  private var headerBar: some View {
    HStack(spacing: 12) {
      Button {
        generateStep1()
      } label: {
        Label("Generate (Step 1)", systemImage: "sparkles")
      }
      .disabled(
        isGenerating || document.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      )

      Button {
        generateStep2()
      } label: {
        Label("Generate (Step 2)", systemImage: "wand.and.stars")
      }
      .disabled(isGenerating || document.outline == nil)

      if isGenerating {
        ProgressView()
          .controlSize(.small)
      }

      Spacer()
      providerStatusView
    }
  }

  @ViewBuilder
  private var generationStatusView: some View {
    if let errorMessage {
      Text(errorMessage)
        .foregroundStyle(.red)
        .textSelection(.enabled)
    } else if let message {
      Text(message)
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
    }
  }

  private var providerStatusView: some View {
    HStack(spacing: 8) {
      if let activeProviderName {
        Text("Provider: \(activeProviderName)")
          .lineLimit(1)
          .truncationMode(.middle)
      } else {
        Text("No active provider")
          .lineLimit(1)
      }

      #if os(macOS)
        Button {
          openSettings()
        } label: {
          Image(systemName: "gearshape")
        }
        .buttonStyle(.plain)
        .help("Provider Settings")
      #endif
    }
    .font(.callout)
    .foregroundStyle(.secondary)
  }

  private var mainTabs: some View {
    TabView {
      inputTab
        .tabItem { Text("Input") }

      previewTab
        .tabItem { Text("Preview") }

      cardsTab
        .tabItem { Text("Cards") }

      todosTab
        .tabItem { Text("Todos") }

      citationsTab
        .tabItem { Text("Citations") }

      historyTab
        .tabItem { Text("History") }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  var activeProviderName: String? {
    (try? fetchActiveProvider())?.name
  }

  var selectedCard: Flashcard? {
    guard let selectedCardID else { return nil }
    return document.flashcards.first(where: { $0.id == selectedCardID })
  }

  var selectedTodo: TodoItem? {
    guard let selectedTodoID else { return nil }
    return document.todos.first(where: { $0.id == selectedTodoID })
  }
}
