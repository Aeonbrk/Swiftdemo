#if os(macOS)
  import Core
  import SwiftData
  import SwiftUI

  struct ProviderEditorView: View {
    private static let keychainService = KeychainStore.llmService
    private static let textAreaCornerRadius: CGFloat = 8

    @Environment(\.modelContext) private var modelContext
    @Bindable var provider: LLMProvider

    @Binding var newAPIKey: String
    @Binding var message: String?

    @State private var isExtraHeadersExpanded = false

    private var hasKey: Bool {
      KeychainStore.hasPassword(
        service: Self.keychainService, account: provider.apiKeyKeychainAccount)
    }

    var body: some View {
      Form {
        Section("基础信息") {
          LabeledContent("名称") {
            TextField("", text: $provider.name)
              .textFieldStyle(.roundedBorder)
          }

          LabeledContent("Base URL") {
            TextField("", text: $provider.baseURL)
              .textFieldStyle(.roundedBorder)
          }

          LabeledContent("Model") {
            TextField("", text: $provider.model)
              .textFieldStyle(.roundedBorder)
          }

          DisclosureGroup("额外 Headers（JSON）", isExpanded: $isExtraHeadersExpanded) {
            Text("用于 OpenRouter 等需要额外 Header 的 Provider（例如 Referer/Title）。")
              .font(.caption)
              .foregroundStyle(.secondary)

            TextEditor(text: $provider.extraHeadersJSON)
              .font(.system(.body, design: .monospaced))
              .frame(minHeight: 160)
              .padding(8)
              .background {
                RoundedRectangle(cornerRadius: Self.textAreaCornerRadius, style: .continuous)
                  .fill(Color(nsColor: .textBackgroundColor))
              }
              .overlay {
                RoundedRectangle(cornerRadius: Self.textAreaCornerRadius, style: .continuous)
                  .stroke(.separator, lineWidth: 1)
              }
          }
        }

        Section("API Key（Keychain）") {
          LabeledContent("状态") {
            Text(hasKey ? "已保存" : "未保存")
              .foregroundStyle(.secondary)
          }

          LabeledContent("新 API Key") {
            HStack(spacing: 8) {
              SecureField("", text: $newAPIKey)
                .textFieldStyle(.roundedBorder)
              Button("保存") {
                saveKey()
              }
              .disabled(newAPIKey.isEmpty)
            }
          }
        }

        Section("激活") {
          LabeledContent("状态") {
            Text(provider.isActive ? "已激活" : "未激活")
              .foregroundStyle(.secondary)
          }

          Button(provider.isActive ? "已激活" : "设为激活") {
            setActive()
          }
          .disabled(provider.isActive)
        }

        if let message, message.isEmpty == false {
          Section {
            Text(message)
              .font(.callout)
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
          }
        }
      }
      .formStyle(.grouped)
      .padding(12)
      .navigationTitle(provider.name)
      .onChange(of: provider.id) { _, _ in
        isExtraHeadersExpanded = false
        newAPIKey = ""
      }
      .onChange(of: provider.name) { _, _ in provider.updatedAt = .now }
      .onChange(of: provider.baseURL) { _, _ in provider.updatedAt = .now }
      .onChange(of: provider.model) { _, _ in provider.updatedAt = .now }
      .onChange(of: provider.extraHeadersJSON) { _, _ in provider.updatedAt = .now }
    }

    private func saveKey() {
      do {
        try KeychainStore.setPassword(
          newAPIKey,
          service: Self.keychainService,
          account: provider.apiKeyKeychainAccount
        )
        newAPIKey = ""
        message = "已保存到 Keychain。"
      } catch {
        message = "保存失败：\(error)"
      }
    }

    private func setActive() {
      do {
        let providers = try modelContext.fetch(FetchDescriptor<LLMProvider>())
        for item in providers {
          item.isActive = item.id == provider.id
          item.updatedAt = .now
        }
        message = "已设为激活。"
      } catch {
        message = "设置失败：\(error)"
      }
    }
  }
#endif
