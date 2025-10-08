import XCTest
@testable import AnimationKitClient
import AnimationKit

#if canImport(Darwin)

final class ClientTests: XCTestCase {
    @MainActor
    func testInitAndHealthMock() async throws {
        let protocolClass = MockHealthURLProtocol.self
        MockHealthURLProtocol.responses["/health"] = (200, try JSONSerialization.data(withJSONObject: ["status": "ok"]))
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
        MockHealthURLProtocol.responses["/evaluate"] = (200, try JSONSerialization.data(withJSONObject: ["value": 0.5]))
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

    @MainActor
    func testSubmitAnimationMock() async throws {
        let protocolClass = MockHealthURLProtocol.self
        MockHealthURLProtocol.responses["/animations"] = (201, try JSONSerialization.data(withJSONObject: ["id": "abc123"]))
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [protocolClass]
        let session = URLSession(configuration: config)
        let client = AnimationServiceClient(.init(baseURL: URL(string: "https://example.com")!, session: session))

        let anim = Animation(duration: 1.0, opacity: Timeline([
            Keyframe(time: 0, value: 0),
            Keyframe(time: 1, value: 1)
        ]))
        let id = try await client.submit(animation: anim)
        XCTAssertEqual(id, "abc123")
    }
}

final class MockHealthURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [String: (Int, Data)] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        guard let path = request.url?.path else { return false }
        return responses.keys.contains(path)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (status, data) = Self.responses[request.url!.path] ?? (200, Data())
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: [
            "Content-Type": "application/json"
        ])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // no-op
    }
}

#endif
