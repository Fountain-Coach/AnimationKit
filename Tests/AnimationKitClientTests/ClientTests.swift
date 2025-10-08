import XCTest
@testable import AnimationKitClient
import AnimationKit

#if canImport(Darwin)

final class ClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockHealthURLProtocol.reset()
    }

    override func tearDown() {
        MockHealthURLProtocol.reset()
        super.tearDown()
    }

    func testInitAndHealthMock() async throws {
        try MockHealthURLProtocol.enqueueJSON(path: "/health", status: 200, object: ["status": "ok"])
        let client = makeClient()
        let status = try await client.health()
        XCTAssertEqual(status, "ok")
    }

    func testEvaluateMock() async throws {
        try MockHealthURLProtocol.enqueueJSON(path: "/evaluate", status: 200, object: ["value": 0.5])
        let client = makeClient()
        let tl = Timeline([
            Keyframe(time: 0, value: 0),
            Keyframe(time: 1, value: 1)
        ])
        let value = try await client.evaluate(timeline: tl, at: 0.5)
        XCTAssertEqual(value, 0.5, accuracy: 1e-9)
    }

    func testBulkEvaluateMock() async throws {
        let payload: [String: Any] = [
            "results": [
                ["t": 0.0, "value": 0.0],
                ["t": 0.5, "value": 0.5],
                ["t": 1.0, "value": 1.0],
            ]
        ]
        try MockHealthURLProtocol.enqueueJSON(path: "/evaluate/bulk", status: 200, object: payload)
        let client = makeClient()
        let tl = Timeline([
            Keyframe(time: 0, value: 0),
            Keyframe(time: 1, value: 1)
        ])
        let samples = try await client.evaluate(timeline: tl, samples: [0.0, 0.5, 1.0])
        XCTAssertEqual(samples.map { $0.value }, [0.0, 0.5, 1.0])
        XCTAssertEqual(samples.map { $0.t }, [0.0, 0.5, 1.0])
    }

    func testSubmitAnimationMock() async throws {
        try MockHealthURLProtocol.enqueueJSON(path: "/animations", status: 201, object: ["id": "abc123"])
        let client = makeClient()
        let anim = Animation(duration: 1.0, opacity: Timeline([
            Keyframe(time: 0, value: 0),
            Keyframe(time: 1, value: 1)
        ]))
        let id = try await client.submit(animation: anim)
        XCTAssertEqual(id, "abc123")
    }

    func testListAndGetAnimations() async throws {
        let iso8601 = ISO8601DateFormatter()
        let updatedAt = iso8601.string(from: Date(timeIntervalSince1970: 100))
        let listPayload: [String: Any] = [
            "items": [
                ["id": "anim-1", "name": "Example", "duration": 1.5, "updatedAt": updatedAt],
            ],
            "nextPageToken": "token-2"
        ]
        try MockHealthURLProtocol.enqueueJSON(path: "/animations", status: 200, object: listPayload)

        let resourcePayload: [String: Any] = [
            "id": "anim-1",
            "name": "Example",
            "tags": ["demo"],
            "animation": [
                "duration": 1.5,
                "opacity": [
                    "keyframes": [
                        ["time": 0.0, "value": 0.0, "easing": "linear"],
                        ["time": 1.5, "value": 1.0, "easing": "linear"],
                    ]
                ]
            ],
            "createdAt": iso8601.string(from: Date(timeIntervalSince1970: 10)),
            "updatedAt": updatedAt
        ]
        try MockHealthURLProtocol.enqueueJSON(path: "/animations/anim-1", status: 200, object: resourcePayload)

        let client = makeClient()
        let page = try await client.listAnimations()
        XCTAssertEqual(page.nextPageToken, "token-2")
        XCTAssertEqual(page.items.first?.id, "anim-1")
        let fetched = try await client.getAnimation(id: "anim-1")
        XCTAssertEqual(fetched.id, "anim-1")
        XCTAssertEqual(fetched.tags, ["demo"])
        XCTAssertEqual(fetched.animation.duration, 1.5)
    }

    func testUpdateAnimation() async throws {
        let iso8601 = ISO8601DateFormatter()
        let updatedAt = iso8601.string(from: Date(timeIntervalSince1970: 42))
        let response: [String: Any] = [
            "id": "anim-1",
            "name": "Updated",
            "tags": ["updated"],
            "animation": [
                "duration": 2.0
            ],
            "updatedAt": updatedAt
        ]
        try MockHealthURLProtocol.enqueueJSON(path: "/animations/anim-1", status: 200, object: response)
        let client = makeClient()
        let draft = AnimationDraft(animation: Animation(duration: 2.0), name: "Updated", tags: ["updated"])
        let updated = try await client.updateAnimation(id: "anim-1", draft: draft)
        XCTAssertEqual(updated.name, "Updated")
        XCTAssertEqual(updated.animation.duration, 2.0)
    }

    func testRetryPolicyRetries() async throws {
        try MockHealthURLProtocol.enqueueJSON(path: "/health", status: 503, object: ["message": "service unavailable"])
        try MockHealthURLProtocol.enqueueJSON(path: "/health", status: 200, object: ["status": "ok"])
        let retry = AnimationServiceClient.RetryConfiguration(maxAttempts: 2, initialBackoff: 0)
        let monitor = RecordingMonitor()
        let client = makeClient(retry: retry, monitor: monitor)
        let status = try await client.health()
        XCTAssertEqual(status, "ok")
        let snapshot = monitor.snapshot()
        XCTAssertEqual(snapshot.willSend.count, 2)
        XCTAssertEqual(snapshot.results.count, 2)
    }

    func testRetriesExhausted() async throws {
        try MockHealthURLProtocol.enqueueJSON(path: "/health", status: 503, object: [:])
        try MockHealthURLProtocol.enqueueJSON(path: "/health", status: 503, object: [:])
        let retry = AnimationServiceClient.RetryConfiguration(maxAttempts: 2, initialBackoff: 0)
        let client = makeClient(retry: retry)
        do {
            _ = try await client.health()
            XCTFail("Expected failure")
        } catch let error as AnimationServiceClient.AnimationServiceError {
            guard case let .retriesExhausted(lastError) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(lastError.statusCode, 503)
        }
    }

    func testMonitorHooksCaptureDurations() async throws {
        try MockHealthURLProtocol.enqueueJSON(path: "/health", status: 200, object: ["status": "ok"])
        let monitor = RecordingMonitor()
        let client = makeClient(monitor: monitor)
        _ = try await client.health()
        let snapshot = monitor.snapshot()
        XCTAssertEqual(snapshot.willSend.count, 1)
        XCTAssertEqual(snapshot.results.count, 1)
        guard case let .success(metadata) = snapshot.results.first else {
            return XCTFail("Expected success metadata")
        }
        XCTAssertGreaterThan(metadata.duration, .zero)
    }

    private func makeClient(
        retry: AnimationServiceClient.RetryConfiguration = .init(maxAttempts: 3, initialBackoff: 0),
        monitor: (any AnimationServiceClientMonitor)? = nil
    ) -> AnimationServiceClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockHealthURLProtocol.self]
        let session = URLSession(configuration: config)
        return AnimationServiceClient(.init(
            baseURL: URL(string: "https://example.com")!,
            session: session,
            retry: retry,
            monitor: monitor
        ))
    }
}

final class MockHealthURLProtocol: URLProtocol {
    struct MockResponse {
        var status: Int
        var headers: [String: String]
        var body: Data
    }

    nonisolated(unsafe) static var responses: [String: [MockResponse]] = [:]
    nonisolated(unsafe) static var recordedRequests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool {
        guard let path = request.url?.path else { return false }
        return responses[path]?.isEmpty == false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.recordedRequests.append(request)
        var queue = Self.responses[url.path] ?? []
        let response = queue.isEmpty ? MockResponse(status: 200, headers: ["Content-Type": "application/json"], body: Data()) : queue.removeFirst()
        Self.responses[url.path] = queue
        let httpResponse = HTTPURLResponse(url: url, statusCode: response.status, httpVersion: nil, headerFields: response.headers)!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func enqueueJSON(path: String, status: Int, object: Any) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let response = MockResponse(status: status, headers: ["Content-Type": "application/json"], body: data)
        responses[path, default: []].append(response)
    }

    static func reset() {
        responses = [:]
        recordedRequests = []
    }
}

final class RecordingMonitor: AnimationServiceClientMonitor, @unchecked Sendable {
    private let queue = DispatchQueue(label: "monitor", attributes: .concurrent)
    private var _willSend: [AnimationServiceClient.RequestMetadata] = []
    private var _results: [AnimationServiceClient.RequestResult] = []

    func client(_ client: AnimationServiceClient, willSend request: AnimationServiceClient.RequestMetadata) {
        queue.async(flags: .barrier) { self._willSend.append(request) }
    }

    func client(
        _ client: AnimationServiceClient,
        didComplete request: AnimationServiceClient.RequestMetadata,
        result: AnimationServiceClient.RequestResult
    ) {
        queue.async(flags: .barrier) { self._results.append(result) }
    }

    func snapshot() -> (willSend: [AnimationServiceClient.RequestMetadata], results: [AnimationServiceClient.RequestResult]) {
        queue.sync { (_willSend, _results) }
    }
}

#endif
