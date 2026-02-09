import Core
import SwiftUI

extension PlanInputView {
  var cardsToolbar: some View {
    AppActionBar {
      HStack(spacing: UIStyle.compactSpacing) {
        Button {
          createFlashcard()
        } label: {
          Label("新建卡片", systemImage: "plus")
        }
        .appPrimaryActionButtonStyle()

        Button(role: .destructive) {
          deleteSelectedFlashcard()
        } label: {
          Label("删除", systemImage: "trash")
        }
        .appSecondaryActionButtonStyle()
        .disabled(selectedCard == nil)

        Spacer(minLength: UIStyle.compactSpacing)

        AppExportMenuButton(
          title: "导出",
          items: [
            AppExportMenuItem(
              id: "cards-tsv",
              title: "导出 TSV",
              systemImage: "tablecells"
            ) {
              exportFlashcardsTSV()
            },
            AppExportMenuItem(
              id: "cards-csv",
              title: "导出 CSV",
              systemImage: "tablecells.fill"
            ) {
              exportFlashcardsCSV()
            }
          ]
        )
        .disabled(document.flashcards.isEmpty)
      }
    }
  }

  var providerHintRow: some View {
    HStack(spacing: UIStyle.compactSpacing) {
      Image(systemName: activeProviderName == nil ? "exclamationmark.shield" : "checkmark.shield")
        .foregroundStyle(activeProviderName == nil ? UIStyle.warningStatusColor : UIStyle.positiveStatusColor)

      if let activeProviderName {
        Text("当前 Provider：\(activeProviderName)")
          .lineLimit(1)
          .truncationMode(.middle)
      } else {
        Text("尚未激活 Provider，请先配置后再生成。")
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }

  var cardsList: some View {
    List(selection: $selectedCardID) {
      ForEach(sortedFlashcards, id: \.id) { card in
        cardRow(card)
          .padding(.horizontal, UIStyle.panelInnerPadding)
          .padding(.vertical, UIStyle.listRowVerticalPadding)
          .appRowGlass()
          .tag(card.id)
          .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
      .onDelete(perform: deleteFlashcards)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .appListContainerGlass()
  }

  var cardsDetail: some View {
    Group {
      if let selectedCard {
        cardEditor(for: selectedCard)
      } else if document.flashcards.isEmpty {
        AppEmptyStatePanel(
          title: "暂无卡片",
          systemImage: "rectangle.stack.badge.plus",
          description: "运行 Step 2 后可自动生成，也可以手动新建。"
        )
      } else {
        AppEmptyStatePanel(
          title: "请选择卡片",
          systemImage: "rectangle.stack"
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  func previewText(for markdown: String) -> some View {
    Group {
      if let attributed = try? AttributedString(markdown: markdown) {
        Text(attributed)
      } else {
        Text(markdown)
      }
    }
    .lineSpacing(4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .textSelection(.enabled)
  }

  func cardRow(_ card: Flashcard) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(card.front.isEmpty ? "（正面为空）" : card.front)
        .lineLimit(2)

      HStack(spacing: 8) {
        Text(card.masteryRaw)
          .font(.caption)
          .foregroundStyle(.secondary)

        if !card.tagsRaw.isEmpty {
          Text(card.tagsRaw)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
  }

  func citationRow(_ citation: Citation) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        Text(citation.verificationStatusRaw)
          .font(.caption)
          .foregroundStyle(.secondary)

        if let url = URL(string: citation.url) {
          Link(citation.url, destination: url)
            .font(.callout)
        } else {
          Text(citation.url)
            .font(.callout)
        }
      }

      if let title = citation.title, !title.isEmpty {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  func generationRow(_ record: GenerationRecord) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(record.statusRaw)
          .font(.caption)
          .foregroundStyle(.secondary)

        Spacer()

        Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text("\(record.providerName) · \(record.model)")
        .font(.callout)

      if let errorSummary = record.errorSummary, !errorSummary.isEmpty {
        Text(errorSummary)
          .font(.caption)
          .foregroundStyle(UIStyle.destructiveStatusColor)
      }
    }
  }
}
