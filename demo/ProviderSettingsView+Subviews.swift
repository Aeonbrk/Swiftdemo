#if os(macOS)
  import Core
  import SwiftUI

  extension ProviderSettingsView {
    var headerBar: some View {
      HStack(spacing: UIStyle.compactSpacing) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Provider 管理")
            .font(.headline)
          Text("统一管理模型、Base URL 与 API Key")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: UIStyle.compactSpacing)

        Button {
          installDefaultProviders()
        } label: {
          Label("导入默认", systemImage: "sparkles")
        }
        .appPrimaryActionButtonStyle()
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
        .appSecondaryActionButtonStyle()
        .help("添加 Provider")

        Button("关闭") {
          closeView()
        }
        .appSecondaryActionButtonStyle()
        .keyboardShortcut(.cancelAction)
        .help("关闭 Provider 面板")
      }
      .padding(.horizontal, UIStyle.toolbarHorizontalPadding)
      .padding(.vertical, UIStyle.toolbarVerticalPadding)
      .appTopBarGlass()
    }

    var emptyState: some View {
      ContentUnavailableView {
        Label("还没有 Provider", systemImage: "key")
      } description: {
        Text("请先添加一个 OpenAI-compatible 的 Provider，并将其设为激活。")
      } actions: {
        Button("导入默认模板") {
          installDefaultProviders()
        }
        .appPrimaryActionButtonStyle()

        Button("添加自定义 Provider") {
          addCustomProvider()
        }
        .appSecondaryActionButtonStyle()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(UIStyle.panelInnerPadding)
      .appPanelGlass()
    }

    var providerListSection: some View {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        HStack {
          Text("Provider 列表")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
          Spacer()
          Text("\(providers.count) 个")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        ScrollView {
          LazyVStack(spacing: UIStyle.compactSpacing) {
            ForEach(providers, id: \.id) { provider in
              providerRow(provider)
            }
          }
          .padding(4)
        }
        .frame(maxHeight: isEmbedded ? 210 : 280)
        .appListContainerGlass()
      }
    }

    func providerRow(_ provider: LLMProvider) -> some View {
      let isSelected = selectedProviderID == provider.id

      return Button {
        selectedProviderID = provider.id
      } label: {
        HStack(spacing: UIStyle.compactSpacing) {
          VStack(alignment: .leading, spacing: 2) {
            Text(provider.name)
              .font(.body.weight(.medium))
              .lineLimit(1)

            Text(provider.baseURL)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.middle)
          }

          Spacer(minLength: UIStyle.compactSpacing)

          if provider.isActive {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(UIStyle.positiveStatusColor)
              .help("当前激活")
          }
        }
        .padding(.horizontal, UIStyle.panelInnerPadding)
        .padding(.vertical, UIStyle.listRowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
          RoundedRectangle(cornerRadius: UIStyle.rowCornerRadius, style: .continuous)
            .fill(isSelected ? Color.accentColor.opacity(UIStyle.selectedRowOpacity) : Color.clear)
        }
        .appRowGlass(interactive: true)
        .appFocusRing(isFocused: focusedProviderID == provider.id)
        .contentShape(Rectangle())
      }
      .focused($focusedProviderID, equals: provider.id)
      .buttonStyle(.plain)
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

    @ViewBuilder
    var detailSection: some View {
      if let provider = selectedProvider {
        ProviderEditorView(
          provider: provider,
          newAPIKey: $newAPIKey,
          message: $message,
          isCompact: isEmbedded
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appPanelGlass()
      } else {
        ContentUnavailableView("请选择一个 Provider", systemImage: "key")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(UIStyle.panelInnerPadding)
          .appPanelGlass()
      }
    }

    @ViewBuilder
    var messageSection: some View {
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

    func closeView() {
      if let onClose {
        onClose()
        return
      }

      dismiss()
    }

    func refreshSelectionIfNeeded() {
      guard providers.isEmpty == false else {
        selectedProviderID = nil
        return
      }

      if let selectedProviderID,
        providers.contains(where: { $0.id == selectedProviderID }) {
        return
      }

      selectedProviderID = providers.first?.id
    }
  }
#endif
