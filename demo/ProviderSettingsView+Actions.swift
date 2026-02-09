#if os(macOS)
  import Core
  import Foundation
  import SwiftData

  private struct ConnectivityProbeInput: Sendable {
    let providerID: UUID
    let baseURL: URL
    let apiKey: String
    let extraHeaders: [String: String]
  }

  extension ProviderSettingsView {
    func addProvider(from preset: LLMProviderPreset) {
      let provider = makeProvider(
        name: preset.name,
        baseURL: preset.baseURL,
        model: preset.model,
        extraHeadersJSON: preset.extraHeadersJSON,
        isActive: providers.isEmpty
      )
      insertAndSelectProvider(provider)
    }

    func addCustomProvider() {
      let provider = makeProvider(
        name: "新 Provider",
        baseURL: "https://api.openai.com/v1",
        model: "gpt-4.1-mini",
        extraHeadersJSON: "{}",
        isActive: providers.isEmpty
      )
      insertAndSelectProvider(provider)
    }

    func installDefaultProviders() {
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
        } else {
          refreshSelectionIfNeeded()
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

    func confirmDeleteProvider() {
      guard let provider = providerPendingDelete else {
        providerIDPendingDelete = nil
        return
      }

      providerIDPendingDelete = nil
      deleteProvider(provider)
    }

    func setActiveProvider(_ provider: LLMProvider) {
      setActiveProviderID(provider.id)
      message = "已设为激活。"
    }

    func deleteProvider(_ provider: LLMProvider) {
      let wasActive = provider.isActive
      let replacement = providers.first(where: { $0.id != provider.id })
      diagnosticsByProviderID.removeValue(forKey: provider.id)
      expandedDiagnosticsProviderIDs.remove(provider.id)
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

    func runConnectivityDiagnostics(for provider: LLMProvider) {
      guard let input = makeConnectivityProbeInput(from: provider) else { return }
      diagnosingProviderID = input.providerID

      Task {
        let probe = ProviderConnectivityProbe()
        let result = await probe.probe(
          baseURL: input.baseURL,
          apiKey: input.apiKey,
          extraHeaders: input.extraHeaders
        )

        await MainActor.run {
          diagnosticsByProviderID[input.providerID] = ProviderDiagnosticsSnapshot(
            result: result,
            checkedAt: .now
          )
          if result.status == .healthy {
            expandedDiagnosticsProviderIDs.remove(input.providerID)
          } else {
            expandedDiagnosticsProviderIDs.insert(input.providerID)
          }
          diagnosingProviderID = nil
        }
      }
    }

    func makeProvider(
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

    func insertAndSelectProvider(_ provider: LLMProvider) {
      modelContext.insert(provider)
      selectedProviderID = provider.id
    }

    func existingProviderKeys() -> Set<String> {
      Set(
        providers.map {
          providerKey(name: $0.name, baseURL: $0.baseURL, model: $0.model)
        }
      )
    }

    func insertMissingDefaultProviders(
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
        if firstInsertedID == nil {
          firstInsertedID = provider.id
        }
        didInsertAny = true
      }

      return (didInsertAny, firstInsertedID)
    }

    func setActiveProviderID(_ id: UUID?, excluding excludedID: UUID? = nil) {
      for item in providers where item.id != excludedID {
        item.isActive = item.id == id
        item.updatedAt = .now
      }
    }

    func providerKey(name: String, baseURL: String, model: String) -> String {
      "\(name.lowercased())|\(baseURL.lowercased())|\(model.lowercased())"
    }

    private func recordConfigurationDiagnostics(providerID: UUID, message: String) {
      diagnosticsByProviderID[providerID] = ProviderDiagnosticsSnapshot(
        result: ProviderConnectivityResult(
          status: .invalidConfiguration,
          latencyMilliseconds: nil,
          httpStatusCode: nil,
          message: message
        ),
        checkedAt: .now
      )
      expandedDiagnosticsProviderIDs.insert(providerID)
      diagnosingProviderID = nil
      self.message = message
    }

    private func makeConnectivityProbeInput(from provider: LLMProvider) -> ConnectivityProbeInput? {
      let providerID = provider.id

      guard let baseURL = URL(string: provider.baseURL) else {
        recordConfigurationDiagnostics(
          providerID: providerID,
          message: "Base URL 无效，请检查格式。"
        )
        return nil
      }

      let apiKey: String
      do {
        apiKey = try KeychainStore.getPassword(
          service: KeychainStore.llmService,
          account: provider.apiKeyKeychainAccount
        ) ?? ""
      } catch {
        recordConfigurationDiagnostics(
          providerID: providerID,
          message: "读取 API Key 失败：\(error)"
        )
        return nil
      }

      guard apiKey.isEmpty == false else {
        recordConfigurationDiagnostics(
          providerID: providerID,
          message: "Provider '\(provider.name)' 缺少 API Key，请先保存。"
        )
        return nil
      }

      let extraHeaders: [String: String]
      do {
        extraHeaders = try parseProviderExtraHeadersJSON(provider.extraHeadersJSON)
      } catch {
        recordConfigurationDiagnostics(
          providerID: providerID,
          message: "额外 Header JSON 格式错误：\(error)"
        )
        return nil
      }

      return ConnectivityProbeInput(
        providerID: providerID,
        baseURL: baseURL,
        apiKey: apiKey,
        extraHeaders: extraHeaders
      )
    }
  }
#endif
