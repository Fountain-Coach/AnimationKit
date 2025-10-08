import XCTest
@testable import AnimationKitClient

final class ClientTests: XCTestCase {
    @MainActor
    func testInitAndHealthMock() async throws {
        let protocolClass = MockHealthURLProtocol.self
        MockHealthURLProtocol.responseData = try JSONSerialization.data(withJSONObject: ["status": "ok"])
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [protocolClass]
        let session = URLSession(configuration: config)
        let client = AnimationServiceClient(.init(baseURL: URL(string: "https://example.com")!, session: session))
        let status = try await client.health()
        XCTAssertEqual(status, "ok")
    }
}

final class MockHealthURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData: Data = Data()

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.path == "/health"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: [
            "Content-Type": "application/json"
        ])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // no-op
    }
}
