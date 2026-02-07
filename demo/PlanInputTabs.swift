import Core
import SwiftUI

extension PlanInputView {
  var inputTab: some View {
    VStack(alignment: .leading, spacing: 12) {
      TextField("标题", text: $document.title)
        .textFieldStyle(.roundedBorder)
        .font(.title3)

      TextEditor(text: $document.rawInput)
        .font(.system(.body, design: .monospaced))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding(12)
  }

  var previewTab: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        if let outline = document.outline, outline.planMarkdown.isEmpty == false {
          previewText(for: outline.planMarkdown)
        } else {
          ContentUnavailableView("暂无预览", systemImage: "doc.text.magnifyingglass")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(12)
  }

  var cardsTab: some View {
    HStack(spacing: 12) {
      VStack(spacing: 8) {
        cardsToolbar
        cardsList
      }
      .frame(minWidth: 320)

      Divider()
      cardsDetail
    }
    .padding(12)
  }

  var todosTab: some View {
    HStack(spacing: 12) {
      VStack(spacing: 8) {
        todosToolbar
        todosList
      }
      .frame(minWidth: 320)

      Divider()
      todosDetail
    }
    .padding(12)
  }

  var citationsTab: some View {
    List {
      ForEach(document.citations.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { citation in
        citationRow(citation)
          .padding(.vertical, 4)
      }
    }
    .listStyle(.inset)
    .padding(12)
  }

  var historyTab: some View {
    List {
      ForEach(document.generations.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { record in
        generationRow(record)
          .padding(.vertical, 4)
      }
    }
    .listStyle(.inset)
    .padding(12)
  }

  private var cardsToolbar: some View {
    HStack(spacing: 8) {
      Button {
        createFlashcard()
      } label: {
        Label("新建", systemImage: "plus")
      }
      .appSecondaryActionButtonStyle()

      Button(role: .destructive) {
        deleteSelectedFlashcard()
      } label: {
        Label("删除", systemImage: "trash")
      }
      .appSecondaryActionButtonStyle()
      .disabled(selectedCard == nil)

      Spacer()

      Button {
        exportFlashcardsTSV()
      } label: {
        Label("导出 TSV", systemImage: "square.and.arrow.up")
      }
      .appSecondaryActionButtonStyle()
      .disabled(document.flashcards.isEmpty)

      Button {
        exportFlashcardsCSV()
      } label: {
        Label("导出 CSV", systemImage: "square.and.arrow.up")
      }
      .appSecondaryActionButtonStyle()
      .disabled(document.flashcards.isEmpty)
    }
  }

  private var cardsList: some View {
    List(selection: $selectedCardID) {
      ForEach(document.flashcards.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { card in
        cardRow(card)
          .tag(card.id)
      }
      .onDelete(perform: deleteFlashcards)
    }
  }

  private var cardsDetail: some View {
    Group {
      if let selectedCard {
        cardEditor(for: selectedCard)
      } else if document.flashcards.isEmpty {
        ContentUnavailableView("暂无卡片", systemImage: "rectangle.stack.badge.plus")
      } else {
        ContentUnavailableView("请选择卡片", systemImage: "rectangle.stack")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var todosToolbar: some View {
    HStack(spacing: 8) {
      Button {
        createTodo()
      } label: {
        Label("新建", systemImage: "plus")
      }
      .appSecondaryActionButtonStyle()

      Button(role: .destructive) {
        deleteSelectedTodo()
      } label: {
        Label("删除", systemImage: "trash")
      }
      .appSecondaryActionButtonStyle()
      .disabled(selectedTodo == nil)

      Spacer()

      Button {
        exportTodosCSV()
      } label: {
        Label("导出 CSV", systemImage: "square.and.arrow.up")
      }
      .appSecondaryActionButtonStyle()
      .disabled(document.todos.isEmpty)
    }
  }

  private var todosList: some View {
    List(selection: $selectedTodoID) {
      ForEach(document.todos.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { todo in
        todoRow(todo)
          .tag(todo.id)
      }
      .onDelete(perform: deleteTodos)
    }
  }

  private var todosDetail: some View {
    Group {
      if let selectedTodo {
        todoEditor(for: selectedTodo)
      } else if document.todos.isEmpty {
        ContentUnavailableView("暂无任务", systemImage: "checklist")
      } else {
        ContentUnavailableView("请选择任务", systemImage: "checkmark.circle")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func previewText(for markdown: String) -> some View {
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

  private func cardRow(_ card: Flashcard) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(card.front.isEmpty ? "(正面为空)" : card.front)
        .lineLimit(2)
      HStack(spacing: 8) {
        Text(card.masteryRaw)
          .font(.caption)
          .foregroundStyle(.secondary)

        if card.tagsRaw.isEmpty == false {
          Text(card.tagsRaw)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
  }

  private func todoRow(_ todo: TodoItem) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(todo.title.isEmpty ? "(无标题)" : todo.title)
        .lineLimit(2)
      HStack(spacing: 8) {
        Text(todo.statusRaw)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(todo.frequencyRaw)
          .font(.caption)
          .foregroundStyle(.secondary)
        if let scheduledAt = todo.scheduledAt {
          Text(scheduledAt.formatted(date: .abbreviated, time: .shortened))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private func citationRow(_ citation: Citation) -> some View {
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

      if let title = citation.title, title.isEmpty == false {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func generationRow(_ record: GenerationRecord) -> some View {
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

      if let errorSummary = record.errorSummary, errorSummary.isEmpty == false {
        Text(errorSummary)
          .font(.caption)
          .foregroundStyle(.red)
      }
    }
  }
}
