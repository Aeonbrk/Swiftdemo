import Foundation

public struct Step2Output: Codable, Equatable {
  public struct Flashcard: Codable, Equatable {
    public var front: String
    public var back: String
    public var tagsRaw: String

    public init(front: String, back: String, tagsRaw: String) {
      self.front = front
      self.back = back
      self.tagsRaw = tagsRaw
    }
  }

  public struct Todo: Codable, Equatable {
    public var title: String
    public var detail: String
    public var estimatedMinutes: Int?
    public var frequencyRaw: String

    public init(title: String, detail: String, estimatedMinutes: Int? = nil, frequencyRaw: String) {
      self.title = title
      self.detail = detail
      self.estimatedMinutes = estimatedMinutes
      self.frequencyRaw = frequencyRaw
    }
  }

  public var flashcards: [Flashcard]
  public var todos: [Todo]

  public init(flashcards: [Flashcard], todos: [Todo]) {
    self.flashcards = flashcards
    self.todos = todos
  }
}
