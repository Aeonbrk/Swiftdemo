import Foundation
import SwiftData

@Model
public final class GenerationRecord {
  @Attribute(.unique)
  public var id: UUID

  public var createdAt: Date

  public var providerName: String
  public var baseURL: String
  public var model: String

  public var promptVersion: String

  public var statusRaw: String
  public var inputSummary: String?
  public var outputSummary: String?

  public var errorSummary: String?
  public var errorDetails: String?

  public var document: PlanDocument?

  public init(
    providerName: String,
    baseURL: String,
    model: String,
    promptVersion: String,
    statusRaw: String,
    inputSummary: String? = nil,
    outputSummary: String? = nil,
    errorSummary: String? = nil,
    errorDetails: String? = nil,
    createdAt: Date = .now
  ) {
    self.id = UUID()
    self.createdAt = createdAt
    self.providerName = providerName
    self.baseURL = baseURL
    self.model = model
    self.promptVersion = promptVersion
    self.statusRaw = statusRaw
    self.inputSummary = inputSummary
    self.outputSummary = outputSummary
    self.errorSummary = errorSummary
    self.errorDetails = errorDetails
  }
}
