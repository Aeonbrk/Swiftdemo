import Core
import SwiftUI

extension PlanInputView {
  func todoEvidenceSection(for todo: TodoItem) -> some View {
    editorCard(title: "证据关联") {
      VStack(alignment: .leading, spacing: 12) {
        Text("已关联主张 \(todo.linkedClaimIDs.count) 条 · 引用 \(todo.linkedCitationIDs.count) 条")
          .font(.caption)
          .foregroundStyle(.secondary)

        if document.claims.isEmpty, document.citations.isEmpty {
          Text("当前文档暂无可关联证据。先运行 Step 1 生成主张和引用。")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          todoEvidenceClaimsSection(for: todo)
          todoEvidenceCitationsSection(for: todo)
        }

        todoEvidenceStaleSection(for: todo)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private func todoEvidenceClaimsSection(for todo: TodoItem) -> some View {
    if !document.claims.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text("主张")
          .font(.subheadline.weight(.semibold))

        ForEach(document.claims.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { claim in
          Toggle(isOn: todoClaimLinkBinding(for: todo, claim: claim)) {
            Text(claim.text.isEmpty ? "（空主张）" : claim.text)
              .lineLimit(2)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func todoEvidenceCitationsSection(for todo: TodoItem) -> some View {
    if !document.citations.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text("引用")
          .font(.subheadline.weight(.semibold))

        ForEach(document.citations.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { citation in
          Toggle(isOn: todoCitationLinkBinding(for: todo, citation: citation)) {
            Text(todoCitationLabel(citation))
              .lineLimit(2)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func todoEvidenceStaleSection(for todo: TodoItem) -> some View {
    let staleClaimIDs = staleClaimIDs(for: todo)
    let staleCitationIDs = staleCitationIDs(for: todo)
    if !staleClaimIDs.isEmpty || !staleCitationIDs.isEmpty {
      VStack(alignment: .leading, spacing: 6) {
        Text("检测到失效证据 ID：\(staleClaimIDs.count + staleCitationIDs.count) 条")
          .font(.caption)
          .foregroundStyle(UIStyle.warningStatusColor)

        Button("清理失效证据 ID") {
          removeStaleEvidenceLinks(for: todo)
        }
        .appSecondaryActionButtonStyle()
      }
    }
  }

  private func todoClaimLinkBinding(for todo: TodoItem, claim: Claim) -> Binding<Bool> {
    let claimID = claim.id.uuidString
    return Binding(
      get: { todo.linkedClaimIDs.contains(claimID) },
      set: { isLinked in
        var ids = todo.linkedClaimIDs
        if isLinked {
          ids.append(claimID)
        } else {
          ids.removeAll { $0 == claimID }
        }
        todo.linkedClaimIDs = ids
        todo.updatedAt = .now
        document.updatedAt = .now
      }
    )
  }

  private func todoCitationLinkBinding(for todo: TodoItem, citation: Citation) -> Binding<Bool> {
    let citationID = citation.id.uuidString
    return Binding(
      get: { todo.linkedCitationIDs.contains(citationID) },
      set: { isLinked in
        var ids = todo.linkedCitationIDs
        if isLinked {
          ids.append(citationID)
        } else {
          ids.removeAll { $0 == citationID }
        }
        todo.linkedCitationIDs = ids
        todo.updatedAt = .now
        document.updatedAt = .now
      }
    )
  }

  private func staleClaimIDs(for todo: TodoItem) -> [String] {
    let validClaimIDs = Set(document.claims.map { $0.id.uuidString })
    return todo.linkedClaimIDs.filter { !validClaimIDs.contains($0) }
  }

  private func staleCitationIDs(for todo: TodoItem) -> [String] {
    let validCitationIDs = Set(document.citations.map { $0.id.uuidString })
    return todo.linkedCitationIDs.filter { !validCitationIDs.contains($0) }
  }

  private func removeStaleEvidenceLinks(for todo: TodoItem) {
    let validClaimIDs = Set(document.claims.map { $0.id.uuidString })
    let validCitationIDs = Set(document.citations.map { $0.id.uuidString })
    todo.linkedClaimIDs = todo.linkedClaimIDs.filter { validClaimIDs.contains($0) }
    todo.linkedCitationIDs = todo.linkedCitationIDs.filter { validCitationIDs.contains($0) }
    todo.updatedAt = .now
    document.updatedAt = .now
  }

  private func todoCitationLabel(_ citation: Citation) -> String {
    if let title = citation.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
      return title
    }
    if !citation.url.isEmpty {
      return citation.url
    }
    return "（未命名引用）"
  }
}
