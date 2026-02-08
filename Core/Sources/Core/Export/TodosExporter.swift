import Foundation

public enum TodosExporter {
  public static func csv(todos: [TodoItem]) -> String {
    var lines: [String] = ["Title,Detail,EstimatedMinutes,Frequency,Status,ScheduledAt,DueAt\n"]
    lines.reserveCapacity(todos.count + 1)

    for todo in todos {
      let title = csvField(todo.title)
      let detail = csvField(todo.detail)
      let estimated = todo.estimatedMinutes.map(String.init) ?? ""
      let frequency = csvField(todo.frequencyRaw)
      let status = csvField(todo.statusRaw)
      let scheduledAt = todo.scheduledAt.map { $0.ISO8601Format() } ?? ""
      let dueAt = todo.dueAt.map { $0.ISO8601Format() } ?? ""

      lines.append(
        "\(title),\(detail),\(estimated),\(frequency),\(status),\(scheduledAt),\(dueAt)\n")
    }

    return lines.joined()
  }

  public static func csvExtended(todos: [TodoItem]) -> String {
    var lines: [String] = [
      "Title,Detail,EstimatedMinutes,Frequency,Status,ScheduledAt,DueAt,Priority,CompletedAt,CreatedAt,UpdatedAt\n"
    ]
    lines.reserveCapacity(todos.count + 1)

    for todo in todos {
      let title = csvField(todo.title)
      let detail = csvField(todo.detail)
      let estimated = todo.estimatedMinutes.map(String.init) ?? ""
      let frequency = csvField(todo.frequencyRaw)
      let status = csvField(todo.status.rawValue)
      let scheduledAt = todo.scheduledAt.map { $0.ISO8601Format() } ?? ""
      let dueAt = todo.dueAt.map { $0.ISO8601Format() } ?? ""
      let priority = csvField(todo.priority.rawValue)
      let completedAt = todo.completedAt.map { $0.ISO8601Format() } ?? ""
      let createdAt = todo.createdAt.ISO8601Format()
      let updatedAt = todo.updatedAt.ISO8601Format()

      lines.append(
        "\(title),\(detail),\(estimated),\(frequency),\(status),\(scheduledAt),\(dueAt),\(priority),"
          + "\(completedAt),\(createdAt),\(updatedAt)\n"
      )
    }

    return lines.joined()
  }

  private static func csvField(_ value: String) -> String {
    let sanitized = sanitizeField(value)
    let needsQuotes =
      sanitized.contains(",") || sanitized.contains("\"") || sanitized.contains("\n")
      || sanitized.contains("\r")

    if needsQuotes == false {
      return sanitized
    }

    let escaped = sanitized.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  private static func sanitizeField(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\n", with: "<br>")
  }
}
