import Foundation

public enum FlashcardsExporter {
  public static func tsv(cards: [Flashcard]) -> String {
    var lines: [String] = []
    lines.reserveCapacity(cards.count)

    for card in cards {
      let front = sanitizeTSVField(card.front)
      let back = sanitizeTSVField(card.back)
      let tags = sanitizeTSVField(card.tagsRaw)
      lines.append("\(front)\t\(back)\t\(tags)\n")
    }

    return lines.joined()
  }

  public static func csv(cards: [Flashcard]) -> String {
    var lines: [String] = []
    lines.reserveCapacity(cards.count)

    for card in cards {
      let front = csvField(card.front)
      let back = csvField(card.back)
      let tags = csvField(card.tagsRaw)
      lines.append("\(front),\(back),\(tags)\n")
    }

    return lines.joined()
  }

  private static func sanitizeTSVField(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\t", with: " ")
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\n", with: "<br>")
  }

  private static func csvField(_ value: String) -> String {
    let sanitized = sanitizeCSVField(value)
    let needsQuotes =
      sanitized.contains(",") || sanitized.contains("\"") || sanitized.contains("\n")
      || sanitized.contains("\r")

    if needsQuotes == false {
      return sanitized
    }

    let escaped = sanitized.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  private static func sanitizeCSVField(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\t", with: " ")
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\n", with: "<br>")
  }
}
