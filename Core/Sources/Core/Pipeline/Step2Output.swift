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
    public var statusRaw: String?
    public var priorityRaw: String?
    public var scheduledAtISO8601: String?
    public var dueAtISO8601: String?

    public init(
      title: String,
      detail: String,
      estimatedMinutes: Int? = nil,
      frequencyRaw: String,
      statusRaw: String? = nil,
      priorityRaw: String? = nil,
      scheduledAtISO8601: String? = nil,
      dueAtISO8601: String? = nil
    ) {
      self.title = title
      self.detail = detail
      self.estimatedMinutes = estimatedMinutes
      self.frequencyRaw = frequencyRaw
      self.statusRaw = statusRaw
      self.priorityRaw = priorityRaw
      self.scheduledAtISO8601 = scheduledAtISO8601
      self.dueAtISO8601 = dueAtISO8601
    }
  }

  public var flashcards: [Flashcard]
  public var todos: [Todo]

  public init(flashcards: [Flashcard], todos: [Todo]) {
    self.flashcards = flashcards
    self.todos = todos
  }
}
