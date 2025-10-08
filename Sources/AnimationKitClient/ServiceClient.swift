import Foundation
import OpenAPIURLSession
import OpenAPIRuntime
import AnimationKit

/// Thin façade for the generated OpenAPI client.
public struct AnimationServiceClient: Sendable {
    public struct Configuration: Sendable {
        public var baseURL: URL
        public var session: URLSession
        public init(baseURL: URL, session: URLSession = .shared) {
            self.baseURL = baseURL
            self.session = session
        }
    }

    private let client: Client

    public init(_ config: Configuration) {
        let transport = URLSessionTransport(configuration: .init(session: config.session))
        self.client = Client(serverURL: config.baseURL, transport: transport)
    }

    /// GET /health via generated client.
    public func health() async throws -> String {
        let output = try await client.getHealth(headers: .init())
        return try output.ok.body.json.status
    }

    /// POST /evaluate with DSL-to-transport bridging.
    public func evaluate(timeline: AnimationKit.Timeline, at t: TimeInterval) async throws -> Double {
        let payload = Operations.evaluateTimeline.Input.Body.json(.init(
            timeline: timeline.asGenerated(),
            t: t
        ))
        let output = try await client.evaluateTimeline(body: payload)
        return try output.ok.body.json.value
    }
}

private extension AnimationKit.Easing {
    func asGenerated() -> Components.Schemas.Easing {
        switch self {
        case .linear: return .linear
        case .easeIn: return .easeIn
        case .easeOut: return .easeOut
        case .easeInOut: return .easeInOut
        }
    }
}

private extension AnimationKit.Keyframe {
    func asGenerated() -> Components.Schemas.Keyframe {
        .init(time: time, value: value, easing: easing.asGenerated())
    }
}

private extension AnimationKit.Timeline {
    func asGenerated() -> Components.Schemas.Timeline {
        .init(keyframes: keyframes.map { $0.asGenerated() })
    }
}
