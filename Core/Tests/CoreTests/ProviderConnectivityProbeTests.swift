import Foundation
import Testing

@testable import Core

@Test func providerConnectivityProbeClassifiesHealthyResponse() async throws {
  let responseData = Data("{}".utf8)
  ProbeMockURLProtocol.setHandler(path: "/v1/provider-health/models") { request in
    #expect(request.httpMethod == "GET")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    #expect(request.value(forHTTPHeaderField: "X-Test") == "1")
    return (
      HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
      responseData
    )
  }

  let probe = ProviderConnectivityProbe(urlSession: makeSession())
  let result = await probe.probe(
    baseURL: URL(string: "https://api.example.com/v1/provider-health")!,
    apiKey: "test-key",
    extraHeaders: ["X-Test": "1"]
  )

  #expect(result.status == .healthy)
  #expect(result.httpStatusCode == 200)
  #expect(result.latencyMilliseconds != nil)
  #expect(result.message == nil)
}

@Test func providerConnectivityProbeClassifiesUnauthorized() async throws {
  ProbeMockURLProtocol.setHandler(path: "/v1/provider-auth/models") { request in
    let data = Data("{\"error\":\"invalid api key\"}".utf8)
    return (
      HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!,
      data
    )
  }

  let probe = ProviderConnectivityProbe(urlSession: makeSession())
  let result = await probe.probe(
    baseURL: URL(string: "https://api.example.com/v1/provider-auth")!,
    apiKey: "bad-key",
    extraHeaders: [:]
  )

  #expect(result.status == .unauthorized)
  #expect(result.httpStatusCode == 401)
}

@Test func providerConnectivityProbeClassifiesTimeout() async throws {
  ProbeMockURLProtocol.setHandler(path: "/v1/provider-timeout/models") { _ in
    throw URLError(.timedOut)
  }

  let probe = ProviderConnectivityProbe(urlSession: makeSession())
  let result = await probe.probe(
    baseURL: URL(string: "https://api.example.com/v1/provider-timeout")!,
    apiKey: "test-key",
    extraHeaders: [:]
  )

  #expect(result.status == .timeout)
  #expect(result.httpStatusCode == nil)
}

@Test func providerConnectivityProbeClassifiesNetworkUnavailable() async throws {
  ProbeMockURLProtocol.setHandler(path: "/v1/provider-network/models") { _ in
    throw URLError(.cannotFindHost)
  }

  let probe = ProviderConnectivityProbe(urlSession: makeSession())
  let result = await probe.probe(
    baseURL: URL(string: "https://api.example.com/v1/provider-network")!,
    apiKey: "test-key",
    extraHeaders: [:]
  )

  #expect(result.status == .networkUnavailable)
  #expect(result.httpStatusCode == nil)
}

private func makeSession() -> URLSession {
  let configuration = URLSessionConfiguration.ephemeral
  configuration.protocolClasses = [ProbeMockURLProtocol.self]
  return URLSession(configuration: configuration)
}

private final class ProbeMockURLProtocol: URLProtocol {
  nonisolated(unsafe) private static var handlers:
    [String: (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]
  private static let lock = NSLock()

  static func setHandler(
    path: String,
    handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
  ) {
    lock.lock()
    handlers[path] = handler
    lock.unlock()
  }

  // swiftlint:disable:next static_over_final_class
  override class func canInit(with request: URLRequest) -> Bool { true }
  // swiftlint:disable:next static_over_final_class
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    do {
      let (response, data) = try Self.response(for: request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}

  private static func response(for request: URLRequest) throws -> (HTTPURLResponse, Data) {
    guard let path = request.url?.path else {
      throw URLError(.badURL)
    }

    lock.lock()
    let handler = handlers[path]
    lock.unlock()

    guard let handler else {
      throw URLError(.badServerResponse)
    }
    return try handler(request)
  }
}
