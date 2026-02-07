import Foundation
import SwiftData

@Model
public final class Citation {
  @Attribute(.unique)
  public var id: UUID

  public var url: String
  public var title: String?
  public var quotedText: String?

  public var verificationStatusRaw: String
  public var verificationMetadataJSON: String?

  public var createdAt: Date
  public var updatedAt: Date

  public var document: PlanDocument?
  public var claim: Claim?

  public init(
    url: String,
    title: String? = nil,
    quotedText: String? = nil,
    verificationStatusRaw: String = "unverified",
    verificationMetadataJSON: String? = nil,
    createdAt: Date = .now,
    updatedAt: Date = .now
  ) {
    self.id = UUID()
    self.url = url
    self.title = title
    self.quotedText = quotedText
    self.verificationStatusRaw = verificationStatusRaw
    self.verificationMetadataJSON = verificationMetadataJSON
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
