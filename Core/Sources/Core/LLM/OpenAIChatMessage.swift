import Foundation

public struct OpenAIChatMessage: Codable, Equatable {
  public enum Role: String, Codable {
    case system
    case user
    case assistant
  }

  public var role: Role
  public var content: String

  public init(role: Role, content: String) {
    self.role = role
    self.content = content
  }
}
