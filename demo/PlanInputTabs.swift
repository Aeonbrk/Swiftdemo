import Core
import SwiftUI

extension PlanInputView {
  var inputTab: some View {
    ScrollView {
      AppRouteScaffold {
        AppPanelCard {
          Text("计划标题")
            .font(.caption)
            .foregroundStyle(.secondary)

          TextField("例如：30 天掌握 Swift 并完成项目", text: $document.title)
            .textFieldStyle(.plain)
            .appFieldSurface()
            .font(.title3)
        }

        AppPanelCard {
          Text("原始输入")
            .font(.caption)
            .foregroundStyle(.secondary)

          TextEditor(text: $document.rawInput)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .appFieldSurface(.field)
            .frame(minHeight: 360)
        }
      }
    }
  }

  var previewTab: some View {
    ScrollView {
      AppRouteScaffold {
        if let outline = document.outline, !outline.planMarkdown.isEmpty {
          AppPanelCard {
            previewText(for: outline.planMarkdown)
          }
        } else {
          AppPanelCard {
            AppEmptyStatePanel(
              title: "暂无预览",
              systemImage: "doc.text.magnifyingglass",
              description: "先运行 Step 1，即可在这里查看结构化结果。"
            )
          }
        }
      }
    }
  }

  var cardsTab: some View {
    AppRouteScaffold {
      AppSplitWorkspace(leadingMinWidth: UIStyle.contentColumnMinWidth) {
        cardsToolbar
        cardsList
      } trailing: {
        cardsDetail
      }
    }
  }

  var todosTab: some View {
    AppRouteScaffold {
      AppSplitWorkspace(leadingMinWidth: UIStyle.contentColumnMinWidth) {
        todosToolbar
        todosList
      } trailing: {
        todosDetail
      }
    }
  }

  var citationsTab: some View {
    AppRouteScaffold {
      AppPanelList {
        ForEach(sortedCitations, id: \.id) { citation in
          citationRow(citation)
            .padding(.horizontal, UIStyle.panelInnerPadding)
            .padding(.vertical, UIStyle.listRowVerticalPadding)
            .appRowGlass()
            .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
      }
    }
  }

  var historyTab: some View {
    AppRouteScaffold {
      AppPanelList {
        ForEach(sortedGenerations, id: \.id) { record in
          generationRow(record)
            .padding(.horizontal, UIStyle.panelInnerPadding)
            .padding(.vertical, UIStyle.listRowVerticalPadding)
            .appRowGlass()
            .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
      }
    }
  }

  private var cardsToolbar: some View {
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

  private var cardsList: some View {
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

  private var cardsDetail: some View {
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

  private var todosToolbar: some View {
    AppActionBar {
      HStack(spacing: UIStyle.compactSpacing) {
        Button {
          createTodo()
        } label: {
          Label("新建任务", systemImage: "plus")
        }
        .appPrimaryActionButtonStyle()

        Button(role: .destructive) {
          deleteSelectedTodo()
        } label: {
          Label("删除", systemImage: "trash")
        }
        .appSecondaryActionButtonStyle()
        .disabled(selectedTodo == nil)

        Spacer(minLength: UIStyle.compactSpacing)

        AppExportMenuButton(
          title: "导出",
          items: [
            AppExportMenuItem(
              id: "todos-csv",
              title: "导出 CSV（兼容）",
              systemImage: "tablecells.fill"
            ) {
              exportTodosCSV()
            },
            AppExportMenuItem(
              id: "todos-csv-extended",
              title: "导出 CSV（扩展）",
              systemImage: "tablecells.badge.ellipsis"
            ) {
              exportTodosExtendedCSV()
            }
          ]
        )
        .disabled(document.todos.isEmpty)
      }
    }
  }

  private var todosList: some View {
    List(selection: $selectedTodoID) {
      ForEach(sortedTodos, id: \.id) { todo in
        todoRow(todo)
          .padding(.horizontal, UIStyle.panelInnerPadding)
          .padding(.vertical, UIStyle.listRowVerticalPadding)
          .appRowGlass()
          .tag(todo.id)
          .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
      .onDelete(perform: deleteTodos)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .appListContainerGlass()
  }

  private var todosDetail: some View {
    Group {
      if let selectedTodo {
        todoEditor(for: selectedTodo)
      } else if document.todos.isEmpty {
        AppEmptyStatePanel(
          title: "暂无任务",
          systemImage: "checklist",
          description: "运行 Step 2 后可自动生成，也可以手动补充。"
        )
      } else {
        AppEmptyStatePanel(
          title: "请选择任务",
          systemImage: "checkmark.circle"
        )
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

  private func todoRow(_ todo: TodoItem) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(todo.title.isEmpty ? "（无标题）" : todo.title)
        .lineLimit(2)

      HStack(spacing: 8) {
        Text(todo.status.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("P:\(todo.priority.rawValue)")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(todo.frequencyRaw)
          .font(.caption)
          .foregroundStyle(.secondary)

        if let completedAt = todo.completedAt {
          Text("完成 \(completedAt.formatted(date: .abbreviated, time: .shortened))")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if let scheduledAt = todo.scheduledAt {
          Text("计划 \(scheduledAt.formatted(date: .abbreviated, time: .shortened))")
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

      if let title = citation.title, !title.isEmpty {
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

      if let errorSummary = record.errorSummary, !errorSummary.isEmpty {
        Text(errorSummary)
          .font(.caption)
          .foregroundStyle(UIStyle.destructiveStatusColor)
      }
    }
  }
}
