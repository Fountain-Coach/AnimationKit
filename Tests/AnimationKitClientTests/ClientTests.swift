import XCTest
@testable import AnimationKitClient
import AnimationKit

final class ClientTests: XCTestCase {
    @MainActor
    func testInitAndHealthMock() async throws {
        let protocolClass = MockHealthURLProtocol.self
        MockHealthURLProtocol.responses["/health"] = try JSONSerialization.data(withJSONObject: ["status": "ok"])
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [protocolClass]
        let session = URLSession(configuration: config)
        let client = AnimationServiceClient(.init(baseURL: URL(string: "https://example.com")!, session: session))
        let status = try await client.health()
        XCTAssertEqual(status, "ok")
    }

    @MainActor
    func testEvaluateMock() async throws {
        let protocolClass = MockHealthURLProtocol.self
        MockHealthURLProtocol.responses["/evaluate"] = try JSONSerialization.data(withJSONObject: ["value": 0.5])
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [protocolClass]
        let session = URLSession(configuration: config)
        let client = AnimationServiceClient(.init(baseURL: URL(string: "https://example.com")!, session: session))

        let tl = Timeline([
            Keyframe(time: 0, value: 0),
            Keyframe(time: 1, value: 1)
        ])
        let value = try await client.evaluate(timeline: tl, at: 0.5)
        XCTAssertEqual(value, 0.5, accuracy: 1e-9)
    }
}

final class MockHealthURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [String: Data] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        guard let path = request.url?.path else { return false }
        return responses.keys.contains(path)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: [
            "Content-Type": "application/json"
        ])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        let data = Self.responses[request.url!.path] ?? Data()
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // no-op
    }
}
