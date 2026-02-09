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
    let embeddedDiagnosticsSection: AnyView?

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

    init(
      provider: LLMProvider,
      newAPIKey: Binding<String>,
      message: Binding<String?>,
      isCompact: Bool,
      embeddedDiagnosticsSection: AnyView? = nil
    ) {
      self.provider = provider
      _newAPIKey = newAPIKey
      _message = message
      self.isCompact = isCompact
      self.embeddedDiagnosticsSection = embeddedDiagnosticsSection
    }

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
          basicInfoSection
          Divider()
          apiKeySection
          Divider()
          activeSection
          localMessageSection
        }
        .padding(.horizontal, UIStyle.panelInnerPadding)
        .padding(.vertical, UIStyle.panelPadding)
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
      sectionBlock(title: "基础信息") {
        providerFormRow("名称") {
          TextField("例如：OpenAI", text: $provider.name)
            .textFieldStyle(.plain)
            .appFieldSurface()
        }

        providerFormRow("Base URL") {
          TextField("https://api.openai.com/v1", text: $provider.baseURL)
            .textFieldStyle(.plain)
            .appFieldSurface()
        }

        providerFormRow("模型（Model）") {
          TextField("例如：gpt-4.1-mini", text: $provider.model)
            .textFieldStyle(.plain)
            .appFieldSurface()
        }

        DisclosureGroup("额外 Headers（JSON）", isExpanded: $isExtraHeadersExpanded) {
          Text("用于 OpenRouter 等需要额外 Header 的 Provider（例如 Referer/Title）。")
            .font(.caption)
            .foregroundStyle(.secondary)

          TextEditor(text: $provider.extraHeadersJSON)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .frame(minHeight: textEditorMinHeight)
            .appFieldSurface(.field)
        }

        if let embeddedDiagnosticsSection {
          Divider()
          embeddedDiagnosticsSection
        }
      }
    }

    private var apiKeySection: some View {
      sectionBlock(title: "API Key（Keychain）") {
        providerFormRow("状态") {
          Text(hasKey ? "已保存" : "未保存")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        providerFormRow("新 API Key") {
          HStack(spacing: UIStyle.compactSpacing) {
            SecureField("输入新的 API Key", text: $newAPIKey)
              .textFieldStyle(.plain)
              .appFieldSurface()

            Button("保存") {
              saveKey()
            }
            .appPrimaryActionButtonStyle()
            .disabled(newAPIKey.isEmpty)
          }
        }
      }
    }

    private var activeSection: some View {
      sectionBlock(
        title: "激活",
        trailing: provider.isActive ? "已激活" : "未激活",
        trailingColor: provider.isActive ? UIStyle.positiveStatusColor : .secondary
      ) {
        if provider.isActive == false {
          HStack {
            Spacer(minLength: UIStyle.providerFormLabelWidth + UIStyle.sectionSpacing)

            Button("设为激活") {
              setActive()
            }
            .appSecondaryActionButtonStyle()

            Spacer()
          }
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

    private func sectionBlock<Content: View>(
      title: String,
      trailing: String? = nil,
      trailingColor: Color = .secondary,
      @ViewBuilder content: () -> Content
    ) -> some View {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        HStack(spacing: UIStyle.compactSpacing) {
          Text(title)
            .font(.headline)

          if let trailing {
            Text(trailing)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(trailingColor)
          }

          Spacer()
        }

        VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
          content()
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func providerFormRow<Content: View>(
      _ title: String,
      @ViewBuilder content: () -> Content
    ) -> some View {
      HStack(alignment: .firstTextBaseline, spacing: UIStyle.sectionSpacing) {
        Text(title)
          .frame(width: UIStyle.providerFormLabelWidth, alignment: .leading)

        content()
          .frame(maxWidth: .infinity, alignment: .leading)
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
