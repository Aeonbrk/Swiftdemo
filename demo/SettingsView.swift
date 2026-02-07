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
      let provider = makeProvider(
        name: preset.name,
        baseURL: preset.baseURL,
        model: preset.model,
        extraHeadersJSON: preset.extraHeadersJSON,
        isActive: providers.isEmpty
      )
      insertAndSelectProvider(provider)
    }

    private func addCustomProvider() {
      let provider = makeProvider(
        name: "新 Provider",
        baseURL: "https://api.openai.com/v1",
        model: "gpt-4.1-mini",
        extraHeadersJSON: "{}",
        isActive: providers.isEmpty
      )
      insertAndSelectProvider(provider)
    }

    private func installDefaultProviders() {
      var existing = existingProviderKeys()
      let hasActiveProvider = providers.contains(where: { $0.isActive })
      let result = insertMissingDefaultProviders(
        existingKeys: &existing,
        shouldActivateFirst: hasActiveProvider == false
      )

      if result.didInsertAny {
        message = "已导入默认 Provider 模板"
        if let firstInsertedID = result.firstInsertedID {
          selectedProviderID = firstInsertedID
        } else if selectedProviderID == nil {
          selectedProviderID = providers.first?.id
        }
        return
      }

      if hasActiveProvider == false, let candidateID = selectedProviderID ?? providers.first?.id {
        setActiveProviderID(candidateID)
        message = "默认 Provider 已存在，已设为激活。"
        return
      }

      message = "默认 Provider 已存在"
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
      setActiveProviderID(provider.id)
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
        setActiveProviderID(replacement?.id, excluding: provider.id)
      }

      if selectedProviderID == provider.id {
        selectedProviderID = replacement?.id
      }

      message = "已删除 Provider"
    }
    private func makeProvider(
      name: String,
      baseURL: String,
      model: String,
      extraHeadersJSON: String,
      isActive: Bool
    ) -> LLMProvider {
      LLMProvider(
        name: name,
        baseURL: baseURL,
        model: model,
        extraHeadersJSON: extraHeadersJSON,
        apiKeyKeychainAccount: "llm-provider-\(UUID().uuidString)",
        isActive: isActive
      )
    }
    private func insertAndSelectProvider(_ provider: LLMProvider) {
      modelContext.insert(provider)
      selectedProviderID = provider.id
    }
    private func existingProviderKeys() -> Set<String> {
      var keys: Set<String> = []
      for provider in providers {
        keys.insert(providerKey(name: provider.name, baseURL: provider.baseURL, model: provider.model))
      }
      return keys
    }
    private func insertMissingDefaultProviders(
      existingKeys: inout Set<String>,
      shouldActivateFirst: Bool
    ) -> (didInsertAny: Bool, firstInsertedID: UUID?) {
      var didInsertAny = false
      var firstInsertedID: UUID?
      var shouldActivateNext = shouldActivateFirst

      for preset in LLMProviderPreset.all {
        let key = providerKey(name: preset.name, baseURL: preset.baseURL, model: preset.model)
        guard existingKeys.contains(key) == false else { continue }
        existingKeys.insert(key)

        let provider = makeProvider(
          name: preset.name,
          baseURL: preset.baseURL,
          model: preset.model,
          extraHeadersJSON: preset.extraHeadersJSON,
          isActive: shouldActivateNext
        )
        shouldActivateNext = false
        modelContext.insert(provider)
        if firstInsertedID == nil { firstInsertedID = provider.id }
        didInsertAny = true
      }

      return (didInsertAny, firstInsertedID)
    }
    private func setActiveProviderID(_ id: UUID?, excluding excludedID: UUID? = nil) {
      for item in providers where item.id != excludedID {
        item.isActive = item.id == id
        item.updatedAt = .now
      }
    }
  }

#endif
