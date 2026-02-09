import Core
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

#if canImport(AppKit)
  import AppKit
#endif

extension PlanInputView {
  func stringBinding<T: AnyObject>(
    for object: T,
    keyPath: ReferenceWritableKeyPath<T, String>
  ) -> Binding<String> {
    Binding(
      get: { object[keyPath: keyPath] },
      set: { newValue in
        object[keyPath: keyPath] = newValue
        markItemUpdatedIfNeeded(object)
        document.updatedAt = .now
      }
    )
  }
  func dateBinding<T: AnyObject>(
    for object: T,
    keyPath: ReferenceWritableKeyPath<T, Date?>
  ) -> Binding<Date> {
    Binding(
      get: { object[keyPath: keyPath] ?? .now },
      set: { newValue in
        object[keyPath: keyPath] = newValue
        markItemUpdatedIfNeeded(object)
        document.updatedAt = .now
      }
    )
  }
  func createFlashcard() {
    let card = Flashcard(front: "", back: "", tagsRaw: "")
    card.document = document
    modelContext.insert(card)
    selectedCardID = card.id
    document.updatedAt = .now
  }
  func deleteSelectedFlashcard() {
    guard let selectedCard else { return }
    modelContext.delete(selectedCard)
    selectedCardID = document.flashcards.first(where: { $0.id != selectedCard.id })?.id
    document.updatedAt = .now
  }
  func deleteFlashcards(at offsets: IndexSet) {
    let sorted = document.flashcards.sorted(by: { $0.createdAt > $1.createdAt })
    for index in offsets {
      modelContext.delete(sorted[index])
    }

    if let selectedCardID,
      !document.flashcards.contains(where: { $0.id == selectedCardID }) {
      self.selectedCardID = document.flashcards.first?.id
    }
    document.updatedAt = .now
  }
  func exportFlashcardsTSV() {
    let content = FlashcardsExporter.tsv(cards: document.flashcards)
    exportTextFile(
      content: content,
      suggestedFileName: "\(document.title)-cards.tsv",
      contentType: .tabSeparatedText
    )
  }
  func exportFlashcardsCSV() {
    let content = FlashcardsExporter.csv(cards: document.flashcards)
    exportTextFile(
      content: content,
      suggestedFileName: "\(document.title)-cards.csv",
      contentType: .commaSeparatedText
    )
  }
  func createTodo() {
    let todo = TodoItem(
      title: "",
      detail: "",
      estimatedMinutes: nil,
      statusRaw: TodoStatus.todo.rawValue,
      priorityRaw: TodoPriority.medium.rawValue,
      frequencyRaw: "once"
    )
    todo.document = document
    modelContext.insert(todo)
    selectedTodoID = todo.id
    document.updatedAt = .now
  }
  func deleteSelectedTodo() {
    guard let selectedTodo else { return }
    modelContext.delete(selectedTodo)
    selectedTodoID = document.todos.first(where: { $0.id != selectedTodo.id })?.id
    document.updatedAt = .now
  }
  func deleteTodos(at offsets: IndexSet) {
    let sorted = document.todos.sorted(by: { $0.createdAt > $1.createdAt })
    for index in offsets {
      modelContext.delete(sorted[index])
    }

    if let selectedTodoID,
      !document.todos.contains(where: { $0.id == selectedTodoID }) {
      self.selectedTodoID = document.todos.first?.id
    }
    document.updatedAt = .now
  }
  func setTodoStatus(_ todo: TodoItem, to status: TodoStatus) {
    todo.status = status
    todo.completedAt = status == .done ? (todo.completedAt ?? .now) : nil
    todo.updatedAt = .now
    document.updatedAt = .now
  }
  func exportTodosCSV() {
    let sorted = document.todos.sorted(by: { $0.createdAt < $1.createdAt })
    let content = TodosExporter.csv(todos: sorted)
    exportTextFile(
      content: content,
      suggestedFileName: "\(document.title)-todos.csv",
      contentType: .commaSeparatedText
    )
  }
  func exportTodosExtendedCSV() {
    let sorted = document.todos.sorted(by: { $0.createdAt < $1.createdAt })
    let content = TodosExporter.csvExtended(todos: sorted)
    exportTextFile(
      content: content,
      suggestedFileName: "\(document.title)-todos-extended.csv",
      contentType: .commaSeparatedText
    )
  }

}
