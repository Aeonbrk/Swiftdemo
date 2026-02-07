import Foundation

public enum Step1OutputDecoder {
  public enum DecodeError: Error {
    case noJSONObjectFound
    case invalidJSON(underlying: Error)
  }

  public static func decode(fromAssistantContent content: String) throws -> Step1Output {
    let jsonString = try extractFirstJSONObjectString(from: content)

    do {
      return try JSONDecoder().decode(Step1Output.self, from: Data(jsonString.utf8))
    } catch {
      throw DecodeError.invalidJSON(underlying: error)
    }
  }

  private static func extractFirstJSONObjectString(from text: String) throws -> String {
    if let fenced = extractFencedCodeBlock(from: text) {
      let trimmed = fenced.trimmingCharacters(in: .whitespacesAndNewlines)
      guard trimmed.hasPrefix("{"), trimmed.hasSuffix("}") else {
        throw DecodeError.noJSONObjectFound
      }
      return trimmed
    }

    if let first = text.firstIndex(of: "{"), let last = text.lastIndex(of: "}") {
      let candidate = String(text[first...last]).trimmingCharacters(in: .whitespacesAndNewlines)
      guard candidate.hasPrefix("{"), candidate.hasSuffix("}") else {
        throw DecodeError.noJSONObjectFound
      }
      return candidate
    }

    throw DecodeError.noJSONObjectFound
  }

  private static func extractFencedCodeBlock(from text: String) -> String? {
    guard let fenceStart = text.range(of: "```") else { return nil }
    let afterFenceStart = text[fenceStart.upperBound...]

    let contentStart: Substring
    if let firstNewline = afterFenceStart.firstIndex(of: "\n") {
      contentStart = afterFenceStart[afterFenceStart.index(after: firstNewline)...]
    } else {
      return nil
    }

    guard let fenceEnd = contentStart.range(of: "```") else { return nil }
    return String(contentStart[..<fenceEnd.lowerBound])
  }
}
