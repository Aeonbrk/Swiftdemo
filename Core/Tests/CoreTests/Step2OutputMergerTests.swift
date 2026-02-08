import Testing

@testable import Core

@Test func step2ReplaceModeUsesIncomingOutput() {
  let existing = Step2Output(
    flashcards: [.init(front: "Old Front", back: "Old Back", tagsRaw: "old")],
    todos: [.init(title: "Old Todo", detail: "Old Detail", estimatedMinutes: 10, frequencyRaw: "once")]
  )
  let incoming = Step2Output(
    flashcards: [.init(front: "New Front", back: "New Back", tagsRaw: "new")],
    todos: [.init(title: "New Todo", detail: "New Detail", estimatedMinutes: 20, frequencyRaw: "daily")]
  )

  let merged = Step2OutputMerger.merge(existing: existing, incoming: incoming, mode: .replace)
  #expect(merged == incoming)
}

@Test func step2MergeModeKeepsExistingOrderAndAppendsUniqueItems() {
  let existing = Step2Output(
    flashcards: [
      .init(front: "A", back: "B", tagsRaw: "x"),
      .init(front: "C", back: "D", tagsRaw: "y")
    ],
    todos: [
      .init(title: "Todo 1", detail: "Detail 1", estimatedMinutes: 10, frequencyRaw: "once"),
      .init(title: "Todo 2", detail: "Detail 2", estimatedMinutes: 20, frequencyRaw: "daily")
    ]
  )
  let incoming = Step2Output(
    flashcards: [
      .init(front: "A", back: "B", tagsRaw: "dup"),
      .init(front: "E", back: "F", tagsRaw: "new")
    ],
    todos: [
      .init(title: "Todo 2", detail: "Detail 2", estimatedMinutes: 30, frequencyRaw: "dup"),
      .init(title: "Todo 3", detail: "Detail 3", estimatedMinutes: nil, frequencyRaw: "weekly")
    ]
  )

  let merged = Step2OutputMerger.merge(existing: existing, incoming: incoming, mode: .merge)

  #expect(merged.flashcards.map(\.front) == ["A", "C", "E"])
  #expect(merged.todos.map(\.title) == ["Todo 1", "Todo 2", "Todo 3"])
}

@Test func step2MergeModeNormalizesWhitespaceAndCaseForDedup() {
  let existing = Step2Output(
    flashcards: [.init(front: "What is Swift?", back: "A language", tagsRaw: "")],
    todos: [.init(title: "Read Chapter", detail: "Concurrency", estimatedMinutes: nil, frequencyRaw: "once")]
  )
  let incoming = Step2Output(
    flashcards: [.init(front: " what is swift? ", back: "a language", tagsRaw: "dup")],
    todos: [.init(title: " read chapter ", detail: "concurrency ", estimatedMinutes: 15, frequencyRaw: "daily")]
  )

  let merged = Step2OutputMerger.merge(existing: existing, incoming: incoming, mode: .merge)

  #expect(merged.flashcards.count == 1)
  #expect(merged.todos.count == 1)
}
