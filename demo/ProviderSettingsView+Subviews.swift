#if os(macOS)
  import Core
  import SwiftUI

  extension ProviderSettingsView {
    private static let diagnosticsStatusTitles: [ProviderConnectivityStatus: String] = [
      .healthy: "连接正常",
      .invalidConfiguration: "配置错误",
      .unauthorized: "鉴权失败",
      .forbidden: "权限受限",
      .rateLimited: "触发限流",
      .serverError: "服务异常",
      .clientError: "请求错误",
      .timeout: "请求超时",
      .networkUnavailable: "网络不可达",
      .invalidResponse: "响应异常",
      .unknown: "未知错误"
    ]

    private static let diagnosticsGuidanceTexts: [ProviderConnectivityStatus: String] = [
      .healthy: "Provider 可用，建议继续在当前配置下运行生成任务。",
      .invalidConfiguration: "请先修正 Base URL、API Key 或额外 Header JSON，再重新测试。",
      .unauthorized: "请检查 API Key 是否正确、是否过期，或是否对应当前 Provider。",
      .forbidden: "当前账号没有访问该模型/端点权限，请检查平台配额与权限策略。",
      .rateLimited: "请求过于频繁，建议稍后重试，或切换到限流更宽松的 Provider。",
      .serverError: "Provider 服务端异常，建议稍后重试或临时切换 Provider。",
      .clientError: "请求参数或头信息可能不兼容，请检查 Base URL、模型名和额外 Header。",
      .timeout: "请求超时，请检查网络质量，必要时稍后重试。",
      .networkUnavailable: "网络不可达，请检查网络连接、DNS、代理/VPN 或公司防火墙策略。",
      .invalidResponse: "返回内容无法识别，可能是网关/代理返回了非标准响应。",
      .unknown: "诊断失败，请查看下方错误详情并重试。"
    ]

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
        VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
          ProviderEditorView(
            provider: provider,
            newAPIKey: $newAPIKey,
            message: $message,
            isCompact: isEmbedded
          )
          .frame(maxWidth: .infinity, alignment: .topLeading)

          diagnosticsSection(for: provider)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      } else {
        ContentUnavailableView("请选择一个 Provider", systemImage: "key")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(UIStyle.panelInnerPadding)
          .appPanelGlass()
      }
    }

    func diagnosticsSection(for provider: LLMProvider) -> some View {
      let snapshot = diagnosticsByProviderID[provider.id]
      let isDiagnosing = diagnosingProviderID == provider.id

      return VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        HStack {
          Text("连通性诊断")
            .font(.headline)
          Spacer()
          if let snapshot {
            Text(snapshot.checkedAt, style: .time)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        HStack(spacing: UIStyle.compactSpacing) {
          Button(isDiagnosing ? "测试中..." : "测试连接") {
            runConnectivityDiagnostics(for: provider)
          }
          .appPrimaryActionButtonStyle()
          .disabled(isDiagnosing)

          if isDiagnosing {
            ProgressView()
              .controlSize(.small)
          }
        }

        if let snapshot {
          diagnosticsSummaryView(snapshot.result)

          DisclosureGroup("诊断详情", isExpanded: diagnosticsDetailsExpandedBinding(for: provider.id)) {
            diagnosticsDetailView(snapshot.result)
              .padding(.top, 4)
          }
          .font(.caption)
          .foregroundStyle(.secondary)
          .disabled(isDiagnosing)
        } else {
          Text("尚未执行诊断。点击“测试连接”可快速检查 API Key、网络可达性与响应状态。")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(UIStyle.panelInnerPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .appPanelGlass()
    }

    func diagnosticsDetailsExpandedBinding(for providerID: UUID) -> Binding<Bool> {
      Binding(
        get: {
          expandedDiagnosticsProviderIDs.contains(providerID)
        },
        set: { isExpanded in
          if isExpanded {
            expandedDiagnosticsProviderIDs.insert(providerID)
          } else {
            expandedDiagnosticsProviderIDs.remove(providerID)
          }
        }
      )
    }

    @ViewBuilder
    func diagnosticsSummaryView(_ result: ProviderConnectivityResult) -> some View {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        HStack(spacing: UIStyle.compactSpacing) {
          Text(diagnosticsStatusTitle(result.status))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(diagnosticsStatusColor(result.status).opacity(0.2), in: Capsule())
            .foregroundStyle(diagnosticsStatusColor(result.status))

          if let latencyMilliseconds = result.latencyMilliseconds {
            Text("延迟 \(latencyMilliseconds) ms")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          if let statusCode = result.httpStatusCode {
            Text("HTTP \(statusCode)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }

    @ViewBuilder
    func diagnosticsDetailView(_ result: ProviderConnectivityResult) -> some View {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        Text(diagnosticsGuidanceText(result))
          .font(.caption)
          .foregroundStyle(.secondary)

        if let message = result.message, message.isEmpty == false, result.status != .healthy {
          Text(message)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }
      }
    }

    func diagnosticsStatusTitle(_ status: ProviderConnectivityStatus) -> String {
      Self.diagnosticsStatusTitles[status] ?? "未知错误"
    }

    func diagnosticsStatusColor(_ status: ProviderConnectivityStatus) -> Color {
      switch status {
      case .healthy:
        return UIStyle.positiveStatusColor
      case .rateLimited, .timeout, .networkUnavailable:
        return UIStyle.warningStatusColor
      case .invalidConfiguration, .unauthorized, .forbidden, .serverError, .clientError,
        .invalidResponse, .unknown:
        return UIStyle.destructiveStatusColor
      }
    }

    func diagnosticsGuidanceText(_ result: ProviderConnectivityResult) -> String {
      Self.diagnosticsGuidanceTexts[result.status] ?? "诊断失败，请稍后重试。"
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
