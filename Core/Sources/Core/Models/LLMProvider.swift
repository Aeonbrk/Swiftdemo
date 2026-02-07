import Foundation
import SwiftData

@Model
public final class LLMProvider {
  @Attribute(.unique)
  public var id: UUID

  public var name: String
  public var baseURL: String
  public var model: String
  public var extraHeadersJSON: String

  public var apiKeyKeychainAccount: String
  public var isActive: Bool

  public var createdAt: Date
  public var updatedAt: Date

  public init(
    name: String,
    baseURL: String,
    model: String,
    extraHeadersJSON: String = "{}",
    apiKeyKeychainAccount: String,
    isActive: Bool = false,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.name = name
    self.baseURL = baseURL
    self.model = model
    self.extraHeadersJSON = extraHeadersJSON
    self.apiKeyKeychainAccount = apiKeyKeychainAccount
    self.isActive = isActive
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
