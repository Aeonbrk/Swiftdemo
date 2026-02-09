import Foundation

public enum ProviderConnectivityStatus: String, Sendable, Codable {
  case healthy
  case invalidConfiguration
  case unauthorized
  case forbidden
  case rateLimited
  case serverError
  case clientError
  case timeout
  case networkUnavailable
  case invalidResponse
  case unknown
}

public struct ProviderConnectivityResult: Sendable, Equatable {
  public let status: ProviderConnectivityStatus
  public let latencyMilliseconds: Int?
  public let httpStatusCode: Int?
  public let message: String?

  public init(
    status: ProviderConnectivityStatus,
    latencyMilliseconds: Int?,
    httpStatusCode: Int? = nil,
    message: String? = nil
  ) {
    self.status = status
    self.latencyMilliseconds = latencyMilliseconds
    self.httpStatusCode = httpStatusCode
    self.message = message
  }
}

public struct ProviderConnectivityProbe {
  private static let modelsPathComponent = "models"

  private let urlSession: URLSession

  public init(urlSession: URLSession = .shared) {
    self.urlSession = urlSession
  }

  public func probe(
    baseURL: URL,
    apiKey: String,
    extraHeaders: [String: String]
  ) async -> ProviderConnectivityResult {
    var request = URLRequest(url: baseURL.appendingPathComponent(Self.modelsPathComponent))
    request.httpMethod = "GET"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    for (key, value) in extraHeaders {
      request.setValue(value, forHTTPHeaderField: key)
    }

    let start = Date()
    do {
      let (data, response) = try await urlSession.data(for: request)
      let latencyMilliseconds = measureLatencyMilliseconds(since: start)

      guard let httpResponse = response as? HTTPURLResponse else {
        return ProviderConnectivityResult(
          status: .invalidResponse,
          latencyMilliseconds: latencyMilliseconds
        )
      }

      let statusCode = httpResponse.statusCode
      let status = classifyHTTPStatusCode(statusCode)
      return ProviderConnectivityResult(
        status: status,
        latencyMilliseconds: latencyMilliseconds,
        httpStatusCode: statusCode,
        message: status == .healthy ? nil : responseBodySummary(data)
      )
    } catch {
      return makeErrorResult(
        for: error,
        latencyMilliseconds: measureLatencyMilliseconds(since: start)
      )
    }
  }

  private func measureLatencyMilliseconds(since start: Date) -> Int {
    max(0, Int(Date().timeIntervalSince(start) * 1000))
  }

  private func makeErrorResult(
    for error: Error,
    latencyMilliseconds: Int
  ) -> ProviderConnectivityResult {
    ProviderConnectivityResult(
      status: classifyError(error),
      latencyMilliseconds: latencyMilliseconds,
      message: String(describing: error)
    )
  }

  private func classifyHTTPStatusCode(_ statusCode: Int) -> ProviderConnectivityStatus {
    switch statusCode {
    case 200..<300:
      return .healthy
    case 401:
      return .unauthorized
    case 403:
      return .forbidden
    case 429:
      return .rateLimited
    case 500..<600:
      return .serverError
    case 400..<500:
      return .clientError
    default:
      return .unknown
    }
  }

  private func classifyError(_ error: Error) -> ProviderConnectivityStatus {
    guard let urlError = error as? URLError else {
      return .unknown
    }

    if urlError.code == .timedOut {
      return .timeout
    }

    switch urlError.code {
    case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
      .dnsLookupFailed:
      return .networkUnavailable
    default:
      return .unknown
    }
  }

  private func responseBodySummary(_ data: Data) -> String? {
    guard let body = String(data: data, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      body.isEmpty == false else {
      return nil
    }
    return String(body.prefix(280))
  }
}
