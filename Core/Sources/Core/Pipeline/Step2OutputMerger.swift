import Foundation

public enum Step2MergeMode: String, CaseIterable, Codable, Sendable {
  case replace
  case merge
}

public enum Step2OutputMerger {
  public static func merge(
    existing: Step2Output,
    incoming: Step2Output,
    mode: Step2MergeMode
  ) -> Step2Output {
    switch mode {
    case .replace:
      return incoming
    case .merge:
      return Step2Output(
        flashcards: mergeFlashcards(existing: existing.flashcards, incoming: incoming.flashcards),
        todos: mergeTodos(existing: existing.todos, incoming: incoming.todos)
      )
    }
  }

  private static func mergeFlashcards(
    existing: [Step2Output.Flashcard],
    incoming: [Step2Output.Flashcard]
  ) -> [Step2Output.Flashcard] {
    var merged = existing
    var seen = Set(existing.map(flashcardKey))

    for card in incoming {
      let key = flashcardKey(card)
      if seen.insert(key).inserted {
        merged.append(card)
      }
    }

    return merged
  }

  private static func mergeTodos(
    existing: [Step2Output.Todo],
    incoming: [Step2Output.Todo]
  ) -> [Step2Output.Todo] {
    var merged = existing
    var seen = Set(existing.map(todoKey))

    for todo in incoming {
      let key = todoKey(todo)
      if seen.insert(key).inserted {
        merged.append(todo)
      }
    }

    return merged
  }

  private static func flashcardKey(_ item: Step2Output.Flashcard) -> String {
    "\(normalize(item.front))|\(normalize(item.back))"
  }

  private static func todoKey(_ item: Step2Output.Todo) -> String {
    "\(normalize(item.title))|\(normalize(item.detail))"
  }

  private static func normalize(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }
}
