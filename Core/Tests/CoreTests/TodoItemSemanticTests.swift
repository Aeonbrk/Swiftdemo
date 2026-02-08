import Testing

@testable import Core

@Test func todoItemSemanticDefaults() {
  let todo = TodoItem(title: "Task", detail: "Detail")
  #expect(todo.status == .todo)
  #expect(todo.priority == .medium)
  #expect(todo.completedAt == nil)
}

@Test func todoItemSemanticFallbackForLegacyValues() {
  let todo = TodoItem(
    title: "Task",
    detail: "Detail",
    statusRaw: "legacy-status",
    priorityRaw: nil
  )
  #expect(todo.status == .todo)
  #expect(todo.priority == .medium)
}
