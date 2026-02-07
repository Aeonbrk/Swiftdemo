import Core
import SwiftData
import SwiftUI

struct PlanInputView: View {
  @Environment(\.modelContext) var modelContext
  @Query(filter: #Predicate<LLMProvider> { $0.isActive == true }, sort: \LLMProvider.updatedAt, order: .reverse)
  private var activeProviders: [LLMProvider]

  @Bindable var document: PlanDocument

  @State var isGenerating = false
  @State var message: String?
  @State var errorMessage: String?
  @State var selectedCardID: UUID?
  @State var selectedTodoID: UUID?
  @State var isShowingCardBack = false
  #if os(macOS)
    @State private var presentedSheetRoute: PlanInputSheetRoute?
  #endif

  var body: some View {
    VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
      headerBar
      generationStatusView
      mainTabs
    }
    .padding(UIStyle.panelPadding)
    .navigationTitle(document.title)
    .onChange(of: document.title) { _, _ in document.updatedAt = .now }
    .onChange(of: document.rawInput) { _, _ in document.updatedAt = .now }
    .onChange(of: selectedCardID) { _, _ in isShowingCardBack = false }
    #if os(macOS)
      .sheet(item: $presentedSheetRoute) { route in
        switch route {
        case .providerSettings:
          NavigationStack {
            ProviderSettingsView()
          }
          .frame(minWidth: 900, minHeight: 560)
        }
      }
    #endif
  }

  @ViewBuilder
  private var headerBar: some View {
    if #available(iOS 26, macOS 26, *) {
      GlassEffectContainer(spacing: 12) {
        headerBarContent
          .padding(.horizontal, UIStyle.toolbarHorizontalPadding)
          .padding(.vertical, UIStyle.toolbarVerticalPadding)
          .appToolbarSurface()
      }
    } else {
      headerBarContent
        .padding(.horizontal, UIStyle.toolbarHorizontalPadding)
        .padding(.vertical, UIStyle.toolbarVerticalPadding)
        .appToolbarSurface()
    }
  }

  private var headerBarContent: some View {
    HStack(spacing: 12) {
      Button {
        generateStep1()
      } label: {
        Label("生成大纲（Step 1）", systemImage: "sparkles")
      }
      .appPrimaryActionButtonStyle()
      .disabled(
        isGenerating || document.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      )

      Button {
        generateStep2()
      } label: {
        Label("生成任务（Step 2）", systemImage: "wand.and.stars")
      }
      .appSecondaryActionButtonStyle()
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
      generationStatusChip(
        text: errorMessage,
        systemImage: "exclamationmark.triangle.fill",
        color: .red
      )
    } else if let message {
      generationStatusChip(
        text: message,
        systemImage: "checkmark.circle.fill",
        color: .secondary
      )
    }
  }

  private func generationStatusChip(text: String, systemImage: String, color: Color) -> some View {
    HStack(spacing: 8) {
      Image(systemName: systemImage)
        .foregroundStyle(color)
      Text(text)
        .foregroundStyle(color)
        .textSelection(.enabled)
    }
    .font(.callout)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .appStatusChipSurface()
  }

  private var providerStatusView: some View {
    HStack(spacing: 8) {
      Image(systemName: activeProviderName == nil ? "exclamationmark.shield" : "checkmark.shield")
        .foregroundStyle(activeProviderName == nil ? .orange : .green)
      if let activeProviderName {
        Text("Provider：\(activeProviderName)")
          .lineLimit(1)
          .truncationMode(.middle)
      } else {
        Text("未激活 Provider")
          .lineLimit(1)
      }

      #if os(macOS)
        Button {
          presentedSheetRoute = .providerSettings
        } label: {
          Image(systemName: "gearshape")
        }
        .appSecondaryActionButtonStyle()
        .help("打开 Provider 设置")
      #endif
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .font(.callout)
    .foregroundStyle(.secondary)
    .appStatusChipSurface()
  }

  private var mainTabs: some View {
    TabView {
      inputTab
        .tabItem { Text("输入") }

      previewTab
        .tabItem { Text("预览") }

      cardsTab
        .tabItem { Text("卡片") }

      todosTab
        .tabItem { Text("任务") }

      citationsTab
        .tabItem { Text("引用") }

      historyTab
        .tabItem { Text("记录") }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  var activeProviderName: String? {
    activeProviders.first?.name
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

#if os(macOS)
  private enum PlanInputSheetRoute: String, Identifiable {
    case providerSettings
    var id: String { rawValue }
  }
#endif
