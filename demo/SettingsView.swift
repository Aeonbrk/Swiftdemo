#if os(macOS)
  import SwiftUI
  import SwiftData
  import Core

  struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LLMProvider.updatedAt, order: .reverse) private var providers: [LLMProvider]

    @State private var selectedProviderID: UUID?
    @State private var newAPIKey: String = ""
    @State private var message: String?
    @State private var providerIDPendingDelete: UUID?

    private var selectedProvider: LLMProvider? {
      guard let selectedProviderID else { return nil }
      return providers.first(where: { $0.id == selectedProviderID })
    }

    private var providerPendingDelete: LLMProvider? {
      guard let providerIDPendingDelete else { return nil }
      return providers.first(where: { $0.id == providerIDPendingDelete })
    }

    var body: some View {
      NavigationSplitView {
        providerList
      } detail: {
        if providers.isEmpty {
          ContentUnavailableView {
            Label("还没有 Provider", systemImage: "key")
          } description: {
            Text("请先添加一个 OpenAI-compatible 的 Provider，并将其设为激活。")
          } actions: {
            Button("导入默认模板") {
              installDefaultProviders()
            }
            Button("添加自定义 Provider") {
              addCustomProvider()
            }
          }
          .padding(16)
        } else if let provider = selectedProvider {
          ProviderEditorView(
            provider: provider,
            newAPIKey: $newAPIKey,
            message: $message
          )
        } else {
          ContentUnavailableView("请选择一个 Provider", systemImage: "key")
            .padding(16)
        }
      }
      .frame(minWidth: 760, minHeight: 520)
      .onAppear {
        if selectedProviderID == nil {
          selectedProviderID = providers.first?.id
        }
      }
      .alert(
        "删除 Provider？",
        isPresented: Binding(
          get: { providerIDPendingDelete != nil },
          set: { isPresented in
            if isPresented == false { providerIDPendingDelete = nil }
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
          Text("将删除 “\(provider.name)” 并从 Keychain 移除对应的 API Key。")
        } else {
          Text("将删除该 Provider 并从 Keychain 移除对应的 API Key。")
        }
      }
    }

    private var providerList: some View {
      List(selection: $selectedProviderID) {
        ForEach(providers, id: \.id) { provider in
          HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
              Text(provider.name)
                .lineLimit(1)
              Text(provider.baseURL)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            }

            Spacer()

            if provider.isActive {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .help("当前激活")
            }
          }
          .tag(provider.id)
          .contextMenu {
            if provider.isActive == false {
              Button("设为激活") {
                selectedProviderID = provider.id
                setActiveProvider(provider)
              }
            }

            Button(role: .destructive) {
              selectedProviderID = provider.id
              providerIDPendingDelete = provider.id
            } label: {
              Text("删除")
            }
          }
        }
      }
      .listStyle(.sidebar)
      .navigationTitle("服务商")
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Button {
            installDefaultProviders()
          } label: {
            Label("导入默认", systemImage: "sparkles")
          }
          .help("导入默认 Provider 模板")

          Menu {
            Section("模板") {
              ForEach(LLMProviderPreset.all) { preset in
                Button(preset.name) {
                  addProvider(from: preset)
                }
              }
            }

            Divider()

            Button("自定义") {
              addCustomProvider()
            }
          } label: {
            Label("添加", systemImage: "plus")
          }
          .help("添加 Provider")

          Button(role: .destructive) {
            providerIDPendingDelete = selectedProviderID
          } label: {
            Label("删除", systemImage: "trash")
          }
          .help("删除选中的 Provider")
          .disabled(selectedProviderID == nil)
        }
      }
    }

  }

  extension SettingsView {
    private func addProvider(from preset: LLMProviderPreset) {
      let account = "llm-provider-\(UUID().uuidString)"
      let provider = LLMProvider(
        name: preset.name,
        baseURL: preset.baseURL,
        model: preset.model,
        extraHeadersJSON: preset.extraHeadersJSON,
        apiKeyKeychainAccount: account,
        isActive: providers.isEmpty
      )
      modelContext.insert(provider)
      selectedProviderID = provider.id
    }

    private func addCustomProvider() {
      let account = "llm-provider-\(UUID().uuidString)"
      let provider = LLMProvider(
        name: "新 Provider",
        baseURL: "https://api.openai.com/v1",
        model: "gpt-4.1-mini",
        extraHeadersJSON: "{}",
        apiKeyKeychainAccount: account,
        isActive: providers.isEmpty
      )
      modelContext.insert(provider)
      selectedProviderID = provider.id
    }

    private func installDefaultProviders() {
      var existing: Set<String> = []
      for provider in providers {
        existing.insert(
          providerKey(name: provider.name, baseURL: provider.baseURL, model: provider.model))
      }

      var didInsertAny = false
      let hasActiveProvider = providers.contains(where: { $0.isActive })
      var shouldActivateFirst = hasActiveProvider == false
      var firstInsertedID: UUID?

      for preset in LLMProviderPreset.all {
        let key = providerKey(name: preset.name, baseURL: preset.baseURL, model: preset.model)
        if existing.contains(key) { continue }
        existing.insert(key)

        let account = "llm-provider-\(UUID().uuidString)"
        let provider = LLMProvider(
          name: preset.name,
          baseURL: preset.baseURL,
          model: preset.model,
          extraHeadersJSON: preset.extraHeadersJSON,
          apiKeyKeychainAccount: account,
          isActive: shouldActivateFirst
        )
        shouldActivateFirst = false
        modelContext.insert(provider)
        if firstInsertedID == nil { firstInsertedID = provider.id }
        didInsertAny = true
      }

      if didInsertAny {
        message = "已导入默认 Provider 模板"
        if let firstInsertedID {
          selectedProviderID = firstInsertedID
        } else if selectedProviderID == nil {
          selectedProviderID = providers.first?.id
        }
      } else {
        if hasActiveProvider == false, let candidateID = selectedProviderID ?? providers.first?.id {
          for item in providers {
            item.isActive = item.id == candidateID
            item.updatedAt = .now
          }
          message = "默认 Provider 已存在，已设为激活。"
        } else {
          message = "默认 Provider 已存在"
        }
      }
    }

    private func providerKey(name: String, baseURL: String, model: String) -> String {
      "\(name.lowercased())|\(baseURL.lowercased())|\(model.lowercased())"
    }

    private func confirmDeleteProvider() {
      guard let provider = providerPendingDelete else {
        providerIDPendingDelete = nil
        return
      }
      providerIDPendingDelete = nil
      deleteProvider(provider)
    }

    private func setActiveProvider(_ provider: LLMProvider) {
      for item in providers {
        item.isActive = item.id == provider.id
        item.updatedAt = .now
      }
      message = "已设为激活。"
    }

    private func deleteProvider(_ provider: LLMProvider) {
      let wasActive = provider.isActive
      let replacement = providers.first(where: { $0.id != provider.id })
      modelContext.delete(provider)

      try? KeychainStore.deletePassword(
        service: KeychainStore.llmService,
        account: provider.apiKeyKeychainAccount
      )

      if wasActive {
        for item in providers where item.id != provider.id {
          item.isActive = item.id == replacement?.id
          item.updatedAt = .now
        }
      }

      if selectedProviderID == provider.id {
        selectedProviderID = replacement?.id
      }

      message = "已删除 Provider"
    }
  }

#endif
