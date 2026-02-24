import Core
import Foundation
import SwiftUI

struct ExecutionEvidenceLookup {
  let claimsByID: [String: Claim]
  let citationsByID: [String: Citation]
}

extension PlanInputView {
  private func executionRowStatusColor(_ status: TodoStatus) -> Color {
    switch status {
    case .todo:
      .secondary
    case .doing:
      UIStyle.positiveStatusColor
    case .blocked:
      UIStyle.warningStatusColor
    case .done:
      .secondary
    }
  }

  private func executionRowTimingLabel(for todo: TodoItem) -> String? {
    if let dueAt = todo.dueAt {
      return "截止 \(dueAt.formatted(date: .abbreviated, time: .shortened))"
    }
    if let scheduledAt = todo.scheduledAt {
      return "计划 \(scheduledAt.formatted(date: .abbreviated, time: .shortened))"
    }
    return nil
  }

  private func executionRowSummary(for todo: TodoItem) -> String {
    if let summary = todo.detail.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
      return summary
    }
    return "尚未补充详细说明"
  }

  private func metaChip(
    _ text: String,
    foregroundColor: Color = .secondary,
    backgroundColor: Color = Color.secondary.opacity(0.10)
  ) -> some View {
    Text(text)
      .font(.caption2)
      .foregroundStyle(foregroundColor)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(
        Capsule(style: .continuous)
          .fill(backgroundColor)
      )
  }

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
    let hasLinkedEvidence = !linkedClaims.isEmpty || !linkedCitations.isEmpty

    return Group {
      if hasLinkedEvidence || missingEvidenceCount > 0 {
        VStack(alignment: .leading, spacing: 8) {
          executionEvidenceHeader(
            todo: todo,
            linkedClaimsCount: linkedClaims.count,
            linkedCitationsCount: linkedCitations.count
          )
          executionClaimsPreview(linkedClaims)
          executionCitationsPreview(linkedCitations)
          executionEvidenceFooter(
            hasCitations: !linkedCitations.isEmpty,
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
    if !linkedClaims.isEmpty {
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
    if !linkedCitations.isEmpty {
      VStack(alignment: .leading, spacing: 4) {
        ForEach(Array(linkedCitations.prefix(2)), id: \.id) { citation in
          if !citation.url.isEmpty, let url = URL(string: citation.url) {
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
    if let title = citation.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
      return title
    }
    if !citation.url.isEmpty {
      return citation.url
    }
    return "（未命名引用）"
  }

  func navigateToTodoEvidenceEditor(_ todo: TodoItem) {
    selectedTodoID = todo.id
    #if os(macOS)
      selectedRoute = .todayExecution
    #else
      selectedMainTab = .todayExecution
    #endif
  }

  private func navigateToCitations() {
    selectedArtifactsSecondaryView = .citations
    #if os(macOS)
      selectedRoute = .organizeArtifacts
    #else
      selectedMainTab = .organizeArtifacts
    #endif
  }
  func executionRow(
    _ todo: TodoItem,
    scoreByTodoID: [UUID: Int],
    evidenceLookup: ExecutionEvidenceLookup
  ) -> some View {
    let score = scoreByTodoID[todo.id]
    let linkedClaimCount = executionLinkedClaims(for: todo, evidenceLookup: evidenceLookup).count
    let linkedCitationCount = executionLinkedCitations(for: todo, evidenceLookup: evidenceLookup).count
    let missingEvidenceCount = executionMissingEvidenceCount(for: todo, evidenceLookup: evidenceLookup)

    return VStack(alignment: .leading, spacing: 8) {
      executionRowHeader(for: todo)
      executionRowMeta(
        todo,
        score: score,
        linkedClaimCount: linkedClaimCount,
        linkedCitationCount: linkedCitationCount,
        missingEvidenceCount: missingEvidenceCount
      )
      executionRowActions(for: todo)
    }
  }

  private func executionRowHeader(for todo: TodoItem) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .top, spacing: 8) {
        Text(todo.title.isEmpty ? "（无标题）" : todo.title)
          .font(.body.weight(.medium))
          .lineLimit(2)

        Spacer(minLength: UIStyle.compactSpacing)

        Text(todo.status.rawValue)
          .font(.caption2.weight(.semibold))
          .padding(.horizontal, 6)
          .padding(.vertical, 3)
          .background(
            Capsule(style: .continuous)
              .fill(executionRowStatusColor(todo.status).opacity(0.16))
          )
          .foregroundStyle(executionRowStatusColor(todo.status))
      }

      Text(executionRowSummary(for: todo))
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }

  private func executionRowMeta(
    _ todo: TodoItem,
    score: Int?,
    linkedClaimCount: Int,
    linkedCitationCount: Int,
    missingEvidenceCount: Int
  ) -> some View {
    HStack(spacing: 8) {
      metaChip("优先级 \(todo.priority.rawValue)")

      if let score {
        metaChip("Score \(score)")
      }

      if let timing = executionRowTimingLabel(for: todo) {
        metaChip(timing)
      }

      if linkedClaimCount + linkedCitationCount > 0 {
        metaChip("证据 \(linkedClaimCount + linkedCitationCount)")
      }

      if missingEvidenceCount > 0 {
        metaChip(
          "失效 \(missingEvidenceCount)",
          foregroundColor: UIStyle.warningStatusColor,
          backgroundColor: UIStyle.warningStatusColor.opacity(0.16)
        )
      }

      Spacer(minLength: UIStyle.compactSpacing)
    }
  }

}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
