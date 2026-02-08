import Core
import Foundation
import SwiftUI

struct ExecutionEvidenceLookup {
  let claimsByID: [String: Claim]
  let citationsByID: [String: Citation]
}

extension PlanInputView {
  func executionRowActions(for todo: TodoItem) -> some View {
    HStack(spacing: 8) {
      Button("待办") {
        setTodoStatus(todo, to: .todo)
      }
      .appSecondaryActionButtonStyle()
      .disabled(todo.status == .todo)

      Button("开始") {
        setTodoStatus(todo, to: .doing)
      }
      .appSecondaryActionButtonStyle()
      .disabled(todo.status == .doing)

      Button("阻塞") {
        setTodoStatus(todo, to: .blocked)
      }
      .appSecondaryActionButtonStyle()
      .disabled(todo.status == .blocked)

      Button(todo.status == .done ? "重开" : "完成") {
        setTodoStatus(todo, to: todo.status == .done ? .todo : .done)
      }
      .appPrimaryActionButtonStyle()

      Button(syncActionButtonTitle) {
        syncTodoWithMockRemote(todo)
      }
      .appSecondaryActionButtonStyle()
    }
  }

  func executionRowEvidence(for todo: TodoItem, evidenceLookup: ExecutionEvidenceLookup) -> some View {
    let linkedClaims = executionLinkedClaims(for: todo, evidenceLookup: evidenceLookup)
    let linkedCitations = executionLinkedCitations(for: todo, evidenceLookup: evidenceLookup)
    let missingEvidenceCount = executionMissingEvidenceCount(for: todo, evidenceLookup: evidenceLookup)

    return Group {
      if linkedClaims.isEmpty == false || linkedCitations.isEmpty == false || missingEvidenceCount > 0 {
        VStack(alignment: .leading, spacing: 8) {
          executionEvidenceHeader(
            todo: todo,
            linkedClaimsCount: linkedClaims.count,
            linkedCitationsCount: linkedCitations.count
          )
          executionClaimsPreview(linkedClaims)
          executionCitationsPreview(linkedCitations)
          executionEvidenceFooter(
            hasCitations: linkedCitations.isEmpty == false,
            missingEvidenceCount: missingEvidenceCount
          )
        }
        .padding(8)
        .appChipGlass()
      }
    }
  }

  private func executionEvidenceHeader(
    todo: TodoItem,
    linkedClaimsCount: Int,
    linkedCitationsCount: Int
  ) -> some View {
    HStack(spacing: 8) {
      Label(
        "证据 主张\(linkedClaimsCount) / 引用\(linkedCitationsCount)",
        systemImage: "link.badge.plus"
      )
      .font(.caption)
      .foregroundStyle(.secondary)

      Spacer(minLength: UIStyle.compactSpacing)

      Button("编辑关联") {
        navigateToTodoEvidenceEditor(todo)
      }
      .appSecondaryActionButtonStyle()
    }
  }

  @ViewBuilder
  private func executionClaimsPreview(_ linkedClaims: [Claim]) -> some View {
    if linkedClaims.isEmpty == false {
      VStack(alignment: .leading, spacing: 4) {
        ForEach(Array(linkedClaims.prefix(2)), id: \.id) { claim in
          Text("• \(claim.text.isEmpty ? "（空主张）" : claim.text)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        if linkedClaims.count > 2 {
          Text("… 还有 \(linkedClaims.count - 2) 条主张")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  @ViewBuilder
  private func executionCitationsPreview(_ linkedCitations: [Citation]) -> some View {
    if linkedCitations.isEmpty == false {
      VStack(alignment: .leading, spacing: 4) {
        ForEach(Array(linkedCitations.prefix(2)), id: \.id) { citation in
          if let url = URL(string: citation.url), citation.url.isEmpty == false {
            Link(destination: url) {
              Label(executionCitationTitle(citation), systemImage: "link")
                .font(.caption2)
                .lineLimit(1)
            }
          } else {
            Text("• \(executionCitationTitle(citation))")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        if linkedCitations.count > 2 {
          Text("… 还有 \(linkedCitations.count - 2) 条引用")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  @ViewBuilder
  private func executionEvidenceFooter(hasCitations: Bool, missingEvidenceCount: Int) -> some View {
    HStack(spacing: 8) {
      if hasCitations {
        Button("查看引用页") {
          navigateToCitations()
        }
        .appSecondaryActionButtonStyle()
      }

      if missingEvidenceCount > 0 {
        Text("含 \(missingEvidenceCount) 条失效证据 ID")
          .font(.caption2)
          .foregroundStyle(UIStyle.warningStatusColor)
      }
    }
  }

  private func executionLinkedClaims(
    for todo: TodoItem,
    evidenceLookup: ExecutionEvidenceLookup
  ) -> [Claim] {
    todo.linkedClaimIDs.compactMap { evidenceLookup.claimsByID[$0] }
  }

  private func executionLinkedCitations(
    for todo: TodoItem,
    evidenceLookup: ExecutionEvidenceLookup
  ) -> [Citation] {
    todo.linkedCitationIDs.compactMap { evidenceLookup.citationsByID[$0] }
  }

  private func executionMissingEvidenceCount(
    for todo: TodoItem,
    evidenceLookup: ExecutionEvidenceLookup
  ) -> Int {
    let missingClaimCount = todo.linkedClaimIDs.filter { evidenceLookup.claimsByID[$0] == nil }.count
    let missingCitationCount = todo.linkedCitationIDs.filter { evidenceLookup.citationsByID[$0] == nil }
      .count
    return missingClaimCount + missingCitationCount
  }

  private func executionCitationTitle(_ citation: Citation) -> String {
    if let title = citation.title?.trimmingCharacters(in: .whitespacesAndNewlines), title.isEmpty == false {
      return title
    }
    if citation.url.isEmpty == false {
      return citation.url
    }
    return "（未命名引用）"
  }

  func navigateToTodoEvidenceEditor(_ todo: TodoItem) {
    selectedTodoID = todo.id
    #if os(macOS)
      selectedRoute = .todos
    #else
      selectedMainTab = .todos
    #endif
  }

  private func navigateToCitations() {
    #if os(macOS)
      selectedRoute = .citations
    #else
      selectedMainTab = .citations
    #endif
  }
}
