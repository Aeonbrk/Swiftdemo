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
    @State private var selectedRoute: PlanWorkspaceRoute = .input
    @State private var isProviderInspectorVisible = false
  #endif

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

  var body: some View {
    #if os(macOS)
      macWorkspace
    #else
      iosWorkspace
    #endif
  }
}

extension PlanInputView {
  private var iosWorkspace: some View {
    VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
      headerBar
      generationStatusView
      mainTabs
    }
    .padding(UIStyle.workspacePadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationTitle(document.title)
    .onChange(of: selectedCardID) { _, _ in
      isShowingCardBack = false
    }
    .onChange(of: document.title) { _, _ in
      document.updatedAt = .now
    }
    .onChange(of: document.rawInput) { _, _ in
      document.updatedAt = .now
    }
  }

  @ViewBuilder
  private var headerBar: some View {
    if #available(iOS 26, macOS 26, *) {
      GlassEffectContainer(spacing: UIStyle.compactSpacing) {
        headerBarContent
      }
    } else {
      headerBarContent
    }
  }

  private var headerBarContent: some View {
    HStack(spacing: UIStyle.compactSpacing) {
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

      Spacer(minLength: UIStyle.compactSpacing)
      providerStatusView
    }
    .padding(.horizontal, UIStyle.toolbarHorizontalPadding)
    .padding(.vertical, UIStyle.toolbarVerticalPadding)
    .appTopBarGlass()
  }

  @ViewBuilder
  private var generationStatusView: some View {
    if let errorMessage {
      generationStatusChip(
        text: errorMessage,
        systemImage: "exclamationmark.triangle.fill",
        color: UIStyle.destructiveStatusColor
      )
    } else if let message {
      generationStatusChip(
        text: message,
        systemImage: "checkmark.circle.fill",
        color: UIStyle.positiveStatusColor
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
    .appChipGlass()
  }

  @ViewBuilder
  private var providerStatusView: some View {
    #if os(macOS)
      Button {
        isProviderInspectorVisible = true
      } label: {
        providerStatusChipContent
      }
      .buttonStyle(.plain)
      .appChipGlass(interactive: true)
      .help("点击管理 Provider")
    #else
      providerStatusChipContent
        .appChipGlass()
    #endif
  }

  private var providerStatusChipContent: some View {
    HStack(spacing: 8) {
      Image(systemName: activeProviderName == nil ? "exclamationmark.shield" : "checkmark.shield")
        .foregroundStyle(activeProviderName == nil ? UIStyle.warningStatusColor : UIStyle.positiveStatusColor)

      if let activeProviderName {
        Text("Provider：\(activeProviderName)")
          .lineLimit(1)
          .truncationMode(.middle)
      } else {
        Text("未激活 Provider")
          .lineLimit(1)
      }

      #if os(macOS)
        Label("管理", systemImage: "slider.horizontal.3")
          .font(.caption)
          .foregroundStyle(.secondary)
      #endif
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .font(.callout)
    .foregroundStyle(.secondary)
  }

  private var mainTabs: some View {
    TabView {
      inputTab
        .tabItem { Label("输入", systemImage: "square.and.pencil") }

      previewTab
        .tabItem { Label("预览", systemImage: "doc.text.magnifyingglass") }

      cardsTab
        .tabItem { Label("卡片", systemImage: "rectangle.stack") }

      todosTab
        .tabItem { Label("任务", systemImage: "checklist") }

      citationsTab
        .tabItem { Label("引用", systemImage: "link") }

      historyTab
        .tabItem { Label("记录", systemImage: "clock.arrow.circlepath") }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func syncSelectionWithCurrentData() {
    if let selectedCardID,
      document.flashcards.contains(where: { $0.id == selectedCardID }) == false {
      self.selectedCardID = document.flashcards.first?.id
    }

    if let selectedTodoID,
      document.todos.contains(where: { $0.id == selectedTodoID }) == false {
      self.selectedTodoID = document.todos.first?.id
    }
  }
}

#if os(macOS)
  extension PlanInputView {
    private var macWorkspace: some View {
      VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
        headerBar
        generationStatusView
        macWorkspaceContent
      }
      .padding(UIStyle.workspacePadding)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .navigationTitle(document.title)
      .inspector(isPresented: $isProviderInspectorVisible) {
        providerInspector
      }
      .onAppear {
        syncSelectionWithCurrentData()
        if activeProviderName == nil {
          isProviderInspectorVisible = true
        }
      }
      .onChange(of: activeProviderName) { _, newValue in
        if newValue == nil {
          isProviderInspectorVisible = true
        }
      }
      .onChange(of: document.flashcards.count) { _, _ in
        syncSelectionWithCurrentData()
      }
      .onChange(of: document.todos.count) { _, _ in
        syncSelectionWithCurrentData()
      }
      .onChange(of: selectedCardID) { _, _ in
        isShowingCardBack = false
      }
      .onChange(of: document.title) { _, _ in
        document.updatedAt = .now
      }
      .onChange(of: document.rawInput) { _, _ in
        document.updatedAt = .now
      }
    }

    private var macWorkspaceContent: some View {
      HStack(spacing: UIStyle.workspaceColumnSpacing) {
        PlanWorkspaceSidebarView(selectedRoute: $selectedRoute)
          .frame(
            minWidth: UIStyle.workspaceSidebarMinWidth,
            idealWidth: UIStyle.workspaceSidebarIdealWidth,
            maxWidth: UIStyle.workspaceSidebarIdealWidth
          )

        PlanWorkspaceDetailView(
          selectedRoute: selectedRoute,
          inputView: AnyView(inputTab),
          previewView: AnyView(previewTab),
          cardsView: AnyView(cardsTab),
          todosView: AnyView(todosTab),
          citationsView: AnyView(citationsTab),
          historyView: AnyView(historyTab)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var providerInspector: some View {
      ProviderSettingsView(isEmbedded: true) {
        closeProviderInspector()
      }
      .inspectorColumnWidth(
        min: UIStyle.providerInspectorMinWidth,
        ideal: UIStyle.providerInspectorWidth,
        max: UIStyle.providerInspectorMaxWidth
      )
    }

    private func closeProviderInspector() {
      withAnimation(.snappy(duration: 0.2)) {
        isProviderInspectorVisible = false
      }
    }
  }
#endif
