import Foundation

public enum FlashcardsExporter {
  public static func tsv(cards: [Flashcard]) -> String {
    guard cards.isEmpty == false else {
      return ""
    }

    var lines: [String] = []
    lines.reserveCapacity(cards.count)

    for card in cards {
      lines.append(tsvRow(for: card))
    }

    return lines.joined()
  }

  public static func csv(cards: [Flashcard]) -> String {
    guard cards.isEmpty == false else {
      return ""
    }

    var lines: [String] = []
    lines.reserveCapacity(cards.count)

    for card in cards {
      lines.append(csvRow(for: card))
    }

    return lines.joined()
  }

  private static func tsvRow(for card: Flashcard) -> String {
    let front = sanitizeTSVField(card.front)
    let back = sanitizeTSVField(card.back)
    let tags = sanitizeTSVField(card.tagsRaw)
    return "\(front)\t\(back)\t\(tags)\n"
  }

  private static func csvRow(for card: Flashcard) -> String {
    let front = csvField(card.front)
    let back = csvField(card.back)
    let tags = csvField(card.tagsRaw)
    return "\(front),\(back),\(tags)\n"
  }

  private static func sanitizeTSVField(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\t", with: " ")
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\n", with: "<br>")
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
      .replacingOccurrences(of: "\t", with: " ")
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\n", with: "<br>")
  }
}
