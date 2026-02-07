import Core
import SwiftUI

extension PlanInputView {
  func cardEditor(for card: Flashcard) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        cardReviewSection(for: card)
        cardFieldsSection(for: card)
        cardTextSection(title: "Front", text: stringBinding(for: card, keyPath: \.front), minHeight: 120)
        cardTextSection(title: "Back", text: stringBinding(for: card, keyPath: \.back), minHeight: 200)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 8)
    }
  }

  func todoEditor(for todo: TodoItem) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        todoFieldsSection(for: todo)
        todoSchedulingSection(for: todo)
        todoDetailSection(for: todo)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 8)
    }
  }

  private func cardReviewSection(for card: Flashcard) -> some View {
    GroupBox("Review") {
      VStack(alignment: .leading, spacing: 8) {
        Text(isShowingCardBack ? card.back : card.front)
          .frame(maxWidth: .infinity, alignment: .leading)
          .textSelection(.enabled)
          .padding(.vertical, 4)

        HStack {
          Button {
            isShowingCardBack.toggle()
          } label: {
            Text(isShowingCardBack ? "Show Front" : "Show Back")
          }

          Spacer()
          if let dueAt = card.dueAt {
            Text("Due: \(dueAt.formatted(date: .abbreviated, time: .shortened))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func cardFieldsSection(for card: Flashcard) -> some View {
    GroupBox("Fields") {
      VStack(alignment: .leading, spacing: 12) {
        TextField("Tags", text: stringBinding(for: card, keyPath: \.tagsRaw))

        Picker("Mastery", selection: stringBinding(for: card, keyPath: \.masteryRaw)) {
          Text("new").tag("new")
          Text("learning").tag("learning")
          Text("mature").tag("mature")
          Text("suspended").tag("suspended")
        }
        .pickerStyle(.segmented)

        Toggle("Has due date", isOn: cardHasDueDateBinding(for: card))

        if card.dueAt != nil {
          DatePicker(
            "Due",
            selection: dateBinding(for: card, keyPath: \.dueAt),
            displayedComponents: [.date, .hourAndMinute]
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func cardTextSection(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
    GroupBox(title) {
      TextEditor(text: text)
        .font(.system(.body, design: .monospaced))
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
    GroupBox("Fields") {
      VStack(alignment: .leading, spacing: 12) {
        TextField("Title", text: stringBinding(for: todo, keyPath: \.title))
        TextField("Status", text: stringBinding(for: todo, keyPath: \.statusRaw))
        TextField("Frequency", text: stringBinding(for: todo, keyPath: \.frequencyRaw))

        Toggle("Has estimate", isOn: todoHasEstimateBinding(for: todo))

        if todo.estimatedMinutes != nil {
          Stepper(value: todoEstimatedMinutesBinding(for: todo), in: 5...600, step: 5) {
            Text("Estimated minutes: \(todo.estimatedMinutes ?? 0)")
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func todoSchedulingSection(for todo: TodoItem) -> some View {
    GroupBox("Scheduling") {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Has scheduled time", isOn: todoHasScheduledTimeBinding(for: todo))

        if todo.scheduledAt != nil {
          DatePicker(
            "Scheduled",
            selection: dateBinding(for: todo, keyPath: \.scheduledAt),
            displayedComponents: [.date, .hourAndMinute]
          )
        }

        Toggle("Has due time", isOn: todoHasDueTimeBinding(for: todo))

        if todo.dueAt != nil {
          DatePicker(
            "Due",
            selection: dateBinding(for: todo, keyPath: \.dueAt),
            displayedComponents: [.date, .hourAndMinute]
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func todoDetailSection(for todo: TodoItem) -> some View {
    GroupBox("Detail") {
      TextEditor(text: stringBinding(for: todo, keyPath: \.detail))
        .font(.system(.body, design: .monospaced))
        .frame(minHeight: 240)
    }
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
