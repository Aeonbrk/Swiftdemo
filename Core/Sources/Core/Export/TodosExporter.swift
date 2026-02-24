import Foundation

public enum TodosExporter {
  private static let legacyHeader =
    "Title,Detail,EstimatedMinutes,Frequency,Status,ScheduledAt,DueAt\n"
  private static let extendedHeader =
    "Title,Detail,EstimatedMinutes,Frequency,Status,ScheduledAt,DueAt,Priority,CompletedAt,CreatedAt,UpdatedAt\n"

  public static func csv(todos: [TodoItem]) -> String {
    guard todos.isEmpty == false else {
      return legacyHeader
    }
    return joinedRows(todos, header: legacyHeader, rowBuilder: legacyCSVRow(for:))
  }

  public static func csvExtended(todos: [TodoItem]) -> String {
    guard todos.isEmpty == false else {
      return extendedHeader
    }
    return joinedRows(todos, header: extendedHeader, rowBuilder: extendedCSVRow(for:))
  }

  private static func legacyCSVRow(for todo: TodoItem) -> String {
    let title = csvField(todo.title)
    let detail = csvField(todo.detail)
    let estimated = intString(todo.estimatedMinutes)
    let frequency = csvField(todo.frequencyRaw)
    let status = csvField(todo.statusRaw)
    let scheduledAt = iso8601(todo.scheduledAt)
    let dueAt = iso8601(todo.dueAt)

    return "\(title),\(detail),\(estimated),\(frequency),\(status),\(scheduledAt),\(dueAt)\n"
  }

  private static func extendedCSVRow(for todo: TodoItem) -> String {
    let title = csvField(todo.title)
    let detail = csvField(todo.detail)
    let estimated = intString(todo.estimatedMinutes)
    let frequency = csvField(todo.frequencyRaw)
    let status = csvField(todo.status.rawValue)
    let scheduledAt = iso8601(todo.scheduledAt)
    let dueAt = iso8601(todo.dueAt)
    let priority = csvField(todo.priority.rawValue)
    let completedAt = iso8601(todo.completedAt)
    let createdAt = todo.createdAt.ISO8601Format()
    let updatedAt = todo.updatedAt.ISO8601Format()

    return
      "\(title),\(detail),\(estimated),\(frequency),\(status),\(scheduledAt),\(dueAt),\(priority),"
      + "\(completedAt),\(createdAt),\(updatedAt)\n"
  }

  private static func intString(_ value: Int?) -> String {
    value.map(String.init) ?? ""
  }

  private static func iso8601(_ value: Date?) -> String {
    value.map { $0.ISO8601Format() } ?? ""
  }

  private static func csvField(_ value: String) -> String {
    let sanitizedValue = sanitizeCSVField(value)
    guard requiresQuotes(in: sanitizedValue) else {
      return sanitizedValue
    }

    let escapedValue = sanitizedValue.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escapedValue)\""
  }

  private static func requiresQuotes(in value: String) -> Bool {
    value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
  }

  private static func sanitizeCSVField(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\n", with: "<br>")
  }

  private static func joinedRows<T>(
    _ items: [T],
    header: String,
    rowBuilder: (T) -> String
  ) -> String {
    var lines: [String] = [header]
    lines.reserveCapacity(items.count + 1)

    for item in items {
      lines.append(rowBuilder(item))
    }
    return lines.joined()
  }
}
