import Foundation

public struct Step1Output: Codable, Equatable {
  public struct Claim: Codable, Equatable {
    public var id: String
    public var text: String
    public var importance: Int?
    public var citationIDs: [String]

    public init(id: String, text: String, importance: Int? = nil, citationIDs: [String]) {
      self.id = id
      self.text = text
      self.importance = importance
      self.citationIDs = citationIDs
    }
  }

  public struct Citation: Codable, Equatable {
    public var id: String
    public var url: String
    public var title: String?
    public var quotedText: String?

    public init(id: String, url: String, title: String? = nil, quotedText: String? = nil) {
      self.id = id
      self.url = url
      self.title = title
      self.quotedText = quotedText
    }
  }

  public var planJSON: String
  public var planMarkdown: String
  public var claims: [Claim]
  public var citations: [Citation]

  public init(planJSON: String, planMarkdown: String, claims: [Claim], citations: [Citation]) {
    self.planJSON = planJSON
    self.planMarkdown = planMarkdown
    self.claims = claims
    self.citations = citations
  }
}
