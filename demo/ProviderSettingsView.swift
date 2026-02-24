#if os(macOS)
  import Core
  import SwiftData
  import SwiftUI

  struct ProviderDiagnosticsSnapshot: Sendable {
    let result: ProviderConnectivityResult
    let checkedAt: Date
  }

  @MainActor
  struct ProviderSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \LLMProvider.updatedAt, order: .reverse) var providers: [LLMProvider]

    let isEmbedded: Bool
    let onClose: (() -> Void)?

    @State var selectedProviderID: UUID?
    @State var newAPIKey = ""
    @State var message: String?
    @State var providerIDPendingDelete: UUID?
    @FocusState var focusedProviderID: UUID?
    @State var diagnosingProviderID: UUID?
    @State var diagnosticsByProviderID: [UUID: ProviderDiagnosticsSnapshot] = [:]
    @State var expandedDiagnosticsProviderIDs: Set<UUID> = []
    @State var isProviderListExpanded = true

    var selectedProvider: LLMProvider? {
      guard let selectedProviderID else { return nil }
      return providers.first(where: { $0.id == selectedProviderID })
    }

    var providerPendingDelete: LLMProvider? {
      guard let providerIDPendingDelete else { return nil }
      return providers.first(where: { $0.id == providerIDPendingDelete })
    }

    init(isEmbedded: Bool = false, onClose: (() -> Void)? = nil) {
      self.isEmbedded = isEmbedded
      self.onClose = onClose
    }

    var body: some View {
      VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
        headerBar

        if providers.isEmpty {
          emptyState
        } else {
          providerListSection
          detailSection
        }

        messageSection
      }
      .padding(isEmbedded ? UIStyle.panelInnerPadding : UIStyle.panelPadding)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .onAppear {
        refreshSelectionIfNeeded()
      }
      .onChange(of: providers.count) {
        refreshSelectionIfNeeded()
      }
      .onExitCommand {
        closeView()
      }
      .alert(
        "删除 Provider？",
        isPresented: Binding(
          get: { providerIDPendingDelete != nil },
          set: { isPresented in
            if !isPresented {
              providerIDPendingDelete = nil
            }
          }
        )
      ) {
        Button("取消", role: .cancel) {
          providerIDPendingDelete = nil
        }
        Button("删除", role: .destructive) {
          confirmDeleteProvider()
        }
      } message: {
        if let provider = providerPendingDelete {
          Text("将删除“\(provider.name)”并从 Keychain 移除对应的 API Key。")
        } else {
          Text("将删除该 Provider 并从 Keychain 移除对应的 API Key。")
        }
      }
    }
  }
#endif
