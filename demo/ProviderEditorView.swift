#if os(macOS)
  import Core
  import SwiftData
  import SwiftUI

  struct ProviderEditorView: View {
    private static let keychainService = KeychainStore.llmService

    @Environment(\.modelContext) private var modelContext

    @Bindable var provider: LLMProvider
    @Binding var newAPIKey: String
    @Binding var message: String?

    let isCompact: Bool

    @State private var isExtraHeadersExpanded = false

    private var hasKey: Bool {
      KeychainStore.hasPassword(
        service: Self.keychainService,
        account: provider.apiKeyKeychainAccount
      )
    }

    private var textEditorMinHeight: CGFloat {
      isCompact ? 120 : 160
    }

    private var detailEditorMinHeight: CGFloat {
      isCompact ? 180 : 240
    }

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
          basicInfoSection
          apiKeySection
          activeSection
          localMessageSection
        }
        .padding(UIStyle.panelPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .onChange(of: provider.id) { _, _ in
        isExtraHeadersExpanded = false
        newAPIKey = ""
      }
      .onChange(of: provider.name) { _, _ in
        provider.updatedAt = .now
      }
      .onChange(of: provider.baseURL) { _, _ in
        provider.updatedAt = .now
      }
      .onChange(of: provider.model) { _, _ in
        provider.updatedAt = .now
      }
      .onChange(of: provider.extraHeadersJSON) { _, _ in
        provider.updatedAt = .now
      }
    }

    private var basicInfoSection: some View {
      settingsCard(title: "基础信息") {
        VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
          LabeledContent("名称") {
            TextField("例如：OpenAI", text: $provider.name)
              .textFieldStyle(.plain)
              .appInputSurface()
          }

          LabeledContent("Base URL") {
            TextField("https://api.openai.com/v1", text: $provider.baseURL)
              .textFieldStyle(.plain)
              .appInputSurface()
          }

          LabeledContent("模型（Model）") {
            TextField("例如：gpt-4.1-mini", text: $provider.model)
              .textFieldStyle(.plain)
              .appInputSurface()
          }

          DisclosureGroup("额外 Headers（JSON）", isExpanded: $isExtraHeadersExpanded) {
            Text("用于 OpenRouter 等需要额外 Header 的 Provider（例如 Referer/Title）。")
              .font(.caption)
              .foregroundStyle(.secondary)

            TextEditor(text: $provider.extraHeadersJSON)
              .font(.system(.body, design: .monospaced))
              .frame(minHeight: textEditorMinHeight)
              .appInputSurface()
          }
        }
      }
    }

    private var apiKeySection: some View {
      settingsCard(title: "API Key（Keychain）") {
        VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
          LabeledContent("状态") {
            Text(hasKey ? "已保存" : "未保存")
              .foregroundStyle(.secondary)
          }

          LabeledContent("新 API Key") {
            HStack(spacing: UIStyle.compactSpacing) {
              SecureField("输入新的 API Key", text: $newAPIKey)
                .textFieldStyle(.plain)
                .appInputSurface()

              Button("保存") {
                saveKey()
              }
              .appPrimaryActionButtonStyle()
              .disabled(newAPIKey.isEmpty)
            }
          }
        }
      }
    }

    private var activeSection: some View {
      settingsCard(title: "激活") {
        VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
          LabeledContent("状态") {
            Text(provider.isActive ? "已激活" : "未激活")
              .foregroundStyle(.secondary)
          }

          Button(provider.isActive ? "已激活" : "设为激活") {
            setActive()
          }
          .appSecondaryActionButtonStyle()
          .disabled(provider.isActive)
        }
      }
    }

    @ViewBuilder
    private var localMessageSection: some View {
      if let message, message.isEmpty == false {
        Text(message)
          .font(.callout)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
          .padding(.horizontal, UIStyle.panelInnerPadding)
          .padding(.vertical, 6)
          .appChipGlass()
      }
    }

    private func settingsCard<Content: View>(
      title: String,
      @ViewBuilder content: () -> Content
    ) -> some View {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        Text(title)
          .font(.headline)

        content()
      }
      .padding(UIStyle.panelInnerPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: UIStyle.panelCornerRadius, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      }
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
