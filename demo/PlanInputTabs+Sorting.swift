import Core

extension PlanInputView {
  var sortedFlashcards: [Flashcard] {
    document.flashcards.sorted(by: { $0.createdAt > $1.createdAt })
  }

  var sortedTodos: [TodoItem] {
    document.todos.sorted(by: { $0.createdAt > $1.createdAt })
  }

  var sortedCitations: [Citation] {
    document.citations.sorted(by: { $0.createdAt > $1.createdAt })
  }

  var sortedGenerations: [GenerationRecord] {
    document.generations.sorted(by: { $0.createdAt > $1.createdAt })
  }
}
