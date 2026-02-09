import Core
import SwiftData
import SwiftUI

enum PlanInputMainTab: Hashable {
  case inputMaterial
  case generatePlan
  case organizeArtifacts
  case todayExecution
}

@MainActor
struct PlanInputView: View {
  private static let useImmediateUpdatedAtTouch =
    ProcessInfo.processInfo.environment["DEMO_PERF_USE_IMMEDIATE_UPDATED_AT"] == "1"

  @Environment(\.modelContext) var modelContext
  @Query(filter: #Predicate<LLMProvider> { $0.isActive == true }, sort: \LLMProvider.updatedAt, order: .reverse)
  private var activeProviders: [LLMProvider]

  @Bindable var document: PlanDocument

  @State var isGenerating = false
  @State var message: String?
  @State var errorMessage: String?
  @State var selectedCardID: UUID?
  @State var selectedTodoID: UUID?
  @State var selectedMainTab: PlanInputMainTab = .inputMaterial
  @State var executionFilter: ExecutionDashboardFilter = .today
  @State var step2MergeMode: Step2MergeMode = .replace
  @State var handledRecommendationTodoIDs: Set<UUID> = []
  @State var pendingSyncReviewsByTodoID: [UUID: PendingSyncReview] = [:]
  @State var isExecutionAdvancedExpanded = false
  @State var selectedArtifactsSecondaryView: ArtifactsSecondaryView = .overview
  @State var isShowingCardBack = false
  @State private var updatedAtDebounceTask: Task<Void, Never>?

  #if os(macOS)
    @State var selectedRoute: PlanWorkspaceRoute = .inputMaterial
    @State var isProviderInspectorVisible = false
    @State var routeAutomationTask: Task<Void, Never>?
    @State var performanceAutomationEditCounter: Int = 0
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
      scheduleDocumentUpdatedAtTouch()
    }
    .onChange(of: document.rawInput) { _, _ in
      scheduleDocumentUpdatedAtTouch()
    }
    .onDisappear {
      flushDocumentUpdatedAtTouch()
    }
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

  private var mainTabs: some View {
    TabView(selection: $selectedMainTab) {
      inputMaterialView
        .tabItem { Label("输入素材", systemImage: "square.and.pencil") }
        .tag(PlanInputMainTab.inputMaterial)

      generatePlanView
        .tabItem { Label("生成计划", systemImage: "doc.text.magnifyingglass") }
        .tag(PlanInputMainTab.generatePlan)

      organizeArtifactsView
        .tabItem { Label("整理产物", systemImage: "rectangle.stack") }
        .tag(PlanInputMainTab.organizeArtifacts)

      todayExecutionView
        .tabItem { Label("今日执行", systemImage: "bolt.horizontal.circle") }
        .tag(PlanInputMainTab.todayExecution)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func syncSelectionWithCurrentData() {
    if let selectedCardID,
      !document.flashcards.contains(where: { $0.id == selectedCardID }) {
      self.selectedCardID = document.flashcards.first?.id
    }

    if let selectedTodoID,
      !document.todos.contains(where: { $0.id == selectedTodoID }) {
      self.selectedTodoID = document.todos.first?.id
    }
  }

  private func scheduleDocumentUpdatedAtTouch() {
    if Self.useImmediateUpdatedAtTouch {
      flushDocumentUpdatedAtTouch()
      return
    }

    updatedAtDebounceTask?.cancel()
    updatedAtDebounceTask = Task {
      do {
        try await Task.sleep(nanoseconds: 500_000_000)
      } catch {
        return
      }

      if !Task.isCancelled {
        document.updatedAt = .now
      }
    }
  }

  private func flushDocumentUpdatedAtTouch() {
    updatedAtDebounceTask?.cancel()
    updatedAtDebounceTask = nil
    document.updatedAt = .now
  }
}

#if os(macOS)
  extension PlanInputView {
    private var macWorkspace: some View {
      VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
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
        setupRouteAutomationIfNeeded()
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
        scheduleDocumentUpdatedAtTouch()
      }
      .onChange(of: document.rawInput) { _, _ in
        scheduleDocumentUpdatedAtTouch()
      }
      .onDisappear {
        flushDocumentUpdatedAtTouch()
        routeAutomationTask?.cancel()
        routeAutomationTask = nil
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
          useLegacyRouteSwitchRendering: Self.useLegacyRouteSwitchRendering,
          inputMaterialView: { inputMaterialView },
          generatePlanView: { generatePlanView },
          organizeArtifactsView: { organizeArtifactsView },
          todayExecutionView: { todayExecutionView }
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
