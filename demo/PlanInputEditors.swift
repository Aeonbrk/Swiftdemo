import Core
import SwiftUI

extension PlanInputView {
  func cardEditor(for card: Flashcard) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
        cardReviewSection(for: card)
        cardFieldsSection(for: card)
        cardTextSection(
          title: "卡片正面",
          text: stringBinding(for: card, keyPath: \.front),
          minHeight: 120
        )
        cardTextSection(
          title: "卡片背面",
          text: stringBinding(for: card, keyPath: \.back),
          minHeight: 220
        )
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 8)
    }
  }

  func todoEditor(for todo: TodoItem) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
        todoFieldsSection(for: todo)
        todoSchedulingSection(for: todo)
        todoDetailSection(for: todo)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 8)
    }
  }

  private func cardReviewSection(for card: Flashcard) -> some View {
    editorCard(title: "预览") {
      VStack(alignment: .leading, spacing: 8) {
        Text(isShowingCardBack ? card.back : card.front)
          .frame(maxWidth: .infinity, alignment: .leading)
          .textSelection(.enabled)
          .padding(.vertical, 4)

        HStack {
          Button {
            isShowingCardBack.toggle()
          } label: {
            Text(isShowingCardBack ? "查看正面" : "查看背面")
          }
          .appSecondaryActionButtonStyle()

          Spacer()

          if let dueAt = card.dueAt {
            Text("复习时间：\(dueAt.formatted(date: .abbreviated, time: .shortened))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func cardFieldsSection(for card: Flashcard) -> some View {
    editorCard(title: "字段") {
      VStack(alignment: .leading, spacing: 12) {
        TextField("标签（逗号分隔）", text: stringBinding(for: card, keyPath: \.tagsRaw))
          .textFieldStyle(.plain)
          .appFieldSurface()

        Picker("掌握度", selection: stringBinding(for: card, keyPath: \.masteryRaw)) {
          Text("new").tag("new")
          Text("learning").tag("learning")
          Text("mature").tag("mature")
          Text("suspended").tag("suspended")
        }
        .pickerStyle(.segmented)

        Toggle("设置复习时间", isOn: cardHasDueDateBinding(for: card))

        if card.dueAt != nil {
          DatePicker(
            "复习时间",
            selection: dateBinding(for: card, keyPath: \.dueAt),
            displayedComponents: [.date, .hourAndMinute]
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func cardTextSection(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
    editorCard(title: title) {
      TextEditor(text: text)
        .font(.system(.body, design: .monospaced))
        .scrollContentBackground(.hidden)
        .appFieldSurface(.field)
        .frame(minHeight: minHeight)
    }
  }

  private func cardHasDueDateBinding(for card: Flashcard) -> Binding<Bool> {
    Binding(
      get: { card.dueAt != nil },
      set: { isOn in
        card.dueAt = isOn ? (card.dueAt ?? .now) : nil
        card.updatedAt = .now
        document.updatedAt = .now
      }
    )
  }

  private func todoFieldsSection(for todo: TodoItem) -> some View {
    editorCard(title: "基础字段") {
      VStack(alignment: .leading, spacing: 12) {
        TextField("任务标题", text: stringBinding(for: todo, keyPath: \.title))
          .textFieldStyle(.plain)
          .appFieldSurface()
        TextField("状态（status）", text: stringBinding(for: todo, keyPath: \.statusRaw))
          .textFieldStyle(.plain)
          .appFieldSurface()
        TextField("频率（frequency）", text: stringBinding(for: todo, keyPath: \.frequencyRaw))
          .textFieldStyle(.plain)
          .appFieldSurface()

        Toggle("设置预估时长", isOn: todoHasEstimateBinding(for: todo))

        if todo.estimatedMinutes != nil {
          Stepper(value: todoEstimatedMinutesBinding(for: todo), in: 5...600, step: 5) {
            Text("预估分钟：\(todo.estimatedMinutes ?? 0)")
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func todoSchedulingSection(for todo: TodoItem) -> some View {
    editorCard(title: "时间安排") {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("设置计划时间", isOn: todoHasScheduledTimeBinding(for: todo))

        if todo.scheduledAt != nil {
          DatePicker(
            "计划时间",
            selection: dateBinding(for: todo, keyPath: \.scheduledAt),
            displayedComponents: [.date, .hourAndMinute]
          )
        }

        Toggle("设置截止时间", isOn: todoHasDueTimeBinding(for: todo))

        if todo.dueAt != nil {
          DatePicker(
            "截止时间",
            selection: dateBinding(for: todo, keyPath: \.dueAt),
            displayedComponents: [.date, .hourAndMinute]
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func todoDetailSection(for todo: TodoItem) -> some View {
    editorCard(title: "详细说明") {
      TextEditor(text: stringBinding(for: todo, keyPath: \.detail))
        .font(.system(.body, design: .monospaced))
        .scrollContentBackground(.hidden)
        .appFieldSurface(.field)
        .frame(minHeight: 260)
    }
  }

  private func editorCard<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
      Text(title)
        .font(.headline)

      content()
    }
    .padding(UIStyle.panelInnerPadding)
    .frame(maxWidth: .infinity, alignment: .leading)
    .appPanelGlass()
  }

  private func todoHasEstimateBinding(for todo: TodoItem) -> Binding<Bool> {
    Binding(
      get: { todo.estimatedMinutes != nil },
      set: { isOn in
        todo.estimatedMinutes = isOn ? (todo.estimatedMinutes ?? 30) : nil
        todo.updatedAt = .now
        document.updatedAt = .now
      }
    )
  }

  private func todoEstimatedMinutesBinding(for todo: TodoItem) -> Binding<Int> {
    Binding(
      get: { todo.estimatedMinutes ?? 30 },
      set: { newValue in
        todo.estimatedMinutes = newValue
        todo.updatedAt = .now
        document.updatedAt = .now
      }
    )
  }

  private func todoHasScheduledTimeBinding(for todo: TodoItem) -> Binding<Bool> {
    Binding(
      get: { todo.scheduledAt != nil },
      set: { isOn in
        todo.scheduledAt = isOn ? (todo.scheduledAt ?? .now) : nil
        todo.updatedAt = .now
        document.updatedAt = .now
      }
    )
  }

  private func todoHasDueTimeBinding(for todo: TodoItem) -> Binding<Bool> {
    Binding(
      get: { todo.dueAt != nil },
      set: { isOn in
        todo.dueAt = isOn ? (todo.dueAt ?? .now) : nil
        todo.updatedAt = .now
        document.updatedAt = .now
      }
    )
  }
}
