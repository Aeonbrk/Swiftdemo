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
    mergeDeduplicated(
      existing: existing,
      incoming: incoming,
      keySelector: flashcardKey
    )
  }

  private static func mergeTodos(
    existing: [Step2Output.Todo],
    incoming: [Step2Output.Todo]
  ) -> [Step2Output.Todo] {
    mergeDeduplicated(
      existing: existing,
      incoming: incoming,
      keySelector: todoKey
    )
  }

  private static func mergeDeduplicated<Item>(
    existing: [Item],
    incoming: [Item],
    keySelector: (Item) -> String
  ) -> [Item] {
    var merged = existing
    var seenKeys = Set(existing.map(keySelector))

    for item in incoming {
      let key = keySelector(item)
      if seenKeys.insert(key).inserted {
        merged.append(item)
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
