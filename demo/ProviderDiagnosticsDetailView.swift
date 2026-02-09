#if os(macOS)
  import Core
  import SwiftUI

  struct ProviderDiagnosticsDetailView: View {
    let snapshot: ProviderDiagnosticsSnapshot
    let provider: LLMProvider
    let diagnosticsStatusTitle: (ProviderConnectivityStatus) -> String
    let diagnosticsGuidanceText: (ProviderConnectivityResult) -> String

    var body: some View {
      let result = snapshot.result

      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        diagnosticsDetailRow("Endpoint", value: modelsEndpoint)
        diagnosticsDetailRow("Method", value: "GET")
        diagnosticsDetailRow("状态分类", value: diagnosticsStatusTitle(result.status))
        diagnosticsDetailRow("HTTP", value: result.httpStatusCode.map(String.init) ?? "-")
        diagnosticsDetailRow("延迟", value: result.latencyMilliseconds.map { "\($0) ms" } ?? "-")
        diagnosticsDetailRow("检测时间", value: snapshot.checkedAt.formatted(date: .omitted, time: .standard))

        Divider()

        Text(diagnosticsGuidanceText(result))
          .font(.caption)
          .foregroundStyle(.secondary)

        if let message = truncatedFailureMessage(for: result) {
          Text(message)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }
      }
    }

    private var modelsEndpoint: String {
      let baseURL = provider.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
      if baseURL.hasSuffix("/") {
        return baseURL + "models"
      }
      return baseURL + "/models"
    }

    private func truncatedFailureMessage(for result: ProviderConnectivityResult) -> String? {
      guard result.status != .healthy,
        let message = result.message?.trimmingCharacters(in: .whitespacesAndNewlines),
        message.isEmpty == false
      else {
        return nil
      }

      let limit = 280
      guard message.count > limit else {
        return message
      }

      let endIndex = message.index(message.startIndex, offsetBy: limit)
      return String(message[..<endIndex]) + "…"
    }

    private func diagnosticsDetailRow(_ title: String, value: String) -> some View {
      HStack(alignment: .firstTextBaseline, spacing: UIStyle.sectionSpacing) {
        Text(title)
          .frame(width: UIStyle.providerFormLabelWidth, alignment: .leading)
          .foregroundStyle(.secondary)

        Text(value)
          .frame(maxWidth: .infinity, alignment: .leading)
          .textSelection(.enabled)
      }
    }
  }
#endif
