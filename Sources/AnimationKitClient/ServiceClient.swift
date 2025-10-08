import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import OpenAPIURLSession
import OpenAPIRuntime
import AnimationKit

/// Thin façade for the generated OpenAPI client with retry and monitoring hooks.
public struct AnimationServiceClient: Sendable {
    public struct Configuration: Sendable {
        public var baseURL: URL
        public var session: URLSession
        public var retry: RetryConfiguration
        public var monitor: (any AnimationServiceClientMonitor)?

        public init(
            baseURL: URL,
            session: URLSession = .shared,
            retry: RetryConfiguration = .default,
            monitor: (any AnimationServiceClientMonitor)? = nil
        ) {
            self.baseURL = baseURL
            self.session = session
            self.retry = retry
            self.monitor = monitor
        }
    }

    public struct RetryConfiguration: Sendable {
        public var maxAttempts: Int
        public var initialBackoff: TimeInterval
        public var multiplier: Double
        public var jitter: ClosedRange<Double>?
        public var retryableStatusCodes: Set<Int>
        public var retryableURLErrorCodes: Set<URLError.Code>

        public init(
            maxAttempts: Int = 3,
            initialBackoff: TimeInterval = 0.25,
            multiplier: Double = 2.0,
            jitter: ClosedRange<Double>? = nil,
            retryableStatusCodes: Set<Int> = Set(500...599),
            retryableURLErrorCodes: Set<URLError.Code> = [.networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost]
        ) {
            self.maxAttempts = max(1, maxAttempts)
            self.initialBackoff = max(0, initialBackoff)
            self.multiplier = max(1, multiplier)
            self.jitter = jitter
            self.retryableStatusCodes = retryableStatusCodes
            self.retryableURLErrorCodes = retryableURLErrorCodes
        }

        public static var `default`: RetryConfiguration { RetryConfiguration() }

        func shouldRetry(error: AnimationServiceError) -> Bool {
            switch error {
            case let .http(status: status, reason: _, operationID: _):
                return retryableStatusCodes.contains(status)
            case let .transport(code, _):
                return retryableURLErrorCodes.contains(code)
            case .decoding, .unknown, .retriesExhausted:
                return false
            }
        }

        func backoff(forAttempt attempt: Int) -> TimeInterval {
            guard attempt > 0 else { return 0 }
            let exponent = Double(attempt - 1)
            var delay = initialBackoff * pow(multiplier, exponent)
            if let jitter {
                let jitterSpan = jitter.upperBound - jitter.lowerBound
                if jitterSpan > 0 {
                    delay += Double.random(in: jitter)
                } else {
                    delay += jitter.lowerBound
                }
            }
            return delay
        }
    }

    public enum AnimationServiceError: Error, Sendable {
        case http(status: Int, reason: String?, operationID: String)
        case transport(code: URLError.Code, description: String)
        case decoding(description: String, operationID: String)
        case unknown(description: String)
        indirect case retriesExhausted(lastError: AnimationServiceError)

        public var statusCode: Int? {
            switch self {
            case let .http(status, _, _):
                return status
            case let .retriesExhausted(lastError):
                return lastError.statusCode
            case .transport, .decoding, .unknown:
                return nil
            }
        }
    }

    public struct RequestMetadata: Sendable {
        public var operationID: String
        public var attempt: Int
    }

    public struct ResponseMetadata: Sendable {
        public var statusCode: Int
        public var duration: Duration
    }

    public enum RequestResult: Sendable {
        case success(ResponseMetadata)
        case failure(error: AnimationServiceError, duration: Duration)
    }

    private let configuration: Configuration
    private let client: Client

    public init(_ config: Configuration) {
        let transport = URLSessionTransport(configuration: .init(session: config.session))
        self.client = Client(serverURL: config.baseURL, transport: transport)
        self.configuration = config
    }

    /// GET /health via generated client.
    public func health() async throws -> String {
        try await execute(operationID: "getHealth") {
            let output = try await client.getHealth(headers: .init())
            let status = try output.ok.body.json.status
            return OperationOutcome(value: status, statusCode: 200)
        }
    }

    /// POST /evaluate with DSL-to-transport bridging.
    public func evaluate(timeline: AnimationKit.Timeline, at t: TimeInterval) async throws -> Double {
        let payload = Operations.evaluateTimeline.Input.Body.json(.init(
            timeline: timeline.asGenerated(),
            t: t
        ))
        return try await execute(operationID: "evaluateTimeline") {
            let output = try await client.evaluateTimeline(body: payload)
            return OperationOutcome(value: try output.ok.body.json.value, statusCode: 200)
        }
    }

    /// POST /evaluate/bulk bridging to timeline samples.
    public func evaluate(timeline: AnimationKit.Timeline, samples: [TimeInterval]) async throws -> [EvaluationSample] {
        let body = Operations.evaluateTimelineBulk.Input.Body.json(
            AnimationSerialization.makeBulkRequest(timeline: timeline, samples: samples)
        )
        return try await execute(operationID: "evaluateTimelineBulk") {
            let output = try await client.evaluateTimelineBulk(body: body)
            let samples = AnimationSerialization.fromSchema(try output.ok.body.json)
            return OperationOutcome(value: samples, statusCode: 200)
        }
    }

    /// POST /animations with DSL `Animation`, returns server-side id.
    public func submit(animation: AnimationKit.Animation) async throws -> String {
        let payload = Operations.submitAnimation.Input.Body.json(try AnimationSerialization.toSchema(animation))
        return try await execute(operationID: "submitAnimation") {
            let output = try await client.submitAnimation(body: payload)
            return OperationOutcome(value: try output.created.body.json.id, statusCode: 201)
        }
    }

    /// GET /animations for pagination-aware listings.
    public func listAnimations(pageToken: String? = nil, pageSize: Int? = nil) async throws -> AnimationPage {
        let query = Operations.listAnimations.Input.Query(pageToken: pageToken, pageSize: pageSize)
        return try await execute(operationID: "listAnimations") {
            let output = try await client.listAnimations(query: query, headers: .init())
            let page = try AnimationSerialization.fromSchema(try output.ok.body.json)
            return OperationOutcome(value: page, statusCode: 200)
        }
    }

    /// GET /animations/{id} returning the server resource.
    public func getAnimation(id: String) async throws -> RemoteAnimation {
        return try await execute(operationID: "getAnimation") {
            let output = try await client.getAnimation(path: .init(id: id), headers: .init())
            let resource = try AnimationSerialization.fromSchema(try output.ok.body.json)
            return OperationOutcome(value: resource, statusCode: 200)
        }
    }

    /// PUT /animations/{id} to update name, tags, or timeline data.
    public func updateAnimation(id: String, draft: AnimationDraft) async throws -> RemoteAnimation {
        let body = Operations.updateAnimation.Input.Body.json(try AnimationSerialization.toSchema(draft))
        return try await execute(operationID: "updateAnimation") {
            let output = try await client.updateAnimation(path: .init(id: id), body: body)
            let resource = try AnimationSerialization.fromSchema(try output.ok.body.json)
            return OperationOutcome(value: resource, statusCode: 200)
        }
    }

    private func execute<Value>(
        operationID: String,
        _ work: @escaping () async throws -> OperationOutcome<Value>
    ) async throws -> Value {
        var attempt = 0
        while true {
            attempt += 1
            let metadata = RequestMetadata(operationID: operationID, attempt: attempt)
            configuration.monitor?.client(self, willSend: metadata)

            let clock = ContinuousClock()
            let start = clock.now
            do {
                let result = try await work()
                let end = clock.now
                let duration = start.duration(to: end)
                let response = ResponseMetadata(statusCode: result.statusCode, duration: duration)
                configuration.monitor?.client(self, didComplete: metadata, result: .success(response))
                return result.value
            } catch {
                let end = clock.now
                let duration = start.duration(to: end)
                if error is CancellationError {
                    configuration.monitor?.client(
                        self,
                        didComplete: metadata,
                        result: .failure(error: .unknown(description: "cancelled"), duration: duration)
                    )
                    throw error
                }
                let serviceError = mapError(error, operationID: operationID)
                configuration.monitor?.client(
                    self,
                    didComplete: metadata,
                    result: .failure(error: serviceError, duration: duration)
                )

                if attempt >= configuration.retry.maxAttempts {
                    throw AnimationServiceError.retriesExhausted(lastError: serviceError)
                }
                if !configuration.retry.shouldRetry(error: serviceError) {
                    throw serviceError
                }
                let delay = configuration.retry.backoff(forAttempt: attempt)
                if delay > 0 {
                    let nanos = UInt64((delay * 1_000_000_000).rounded())
                    try await Task.sleep(nanoseconds: nanos)
                } else {
                    await Task.yield()
                }
            }
        }
    }

    private func mapError(_ error: Error, operationID: String) -> AnimationServiceError {
        if let serviceError = error as? AnimationServiceError {
            return serviceError
        }
        if let urlError = error as? URLError {
            return .transport(code: urlError.code, description: urlError.localizedDescription)
        }
        if let decodingError = error as? DecodingError {
            return .decoding(description: String(describing: decodingError), operationID: operationID)
        }
        if let clientError = error as? ClientError {
            if let response = clientError.response {
                let status = response.status.code
                let reason = response.status.reasonPhrase.isEmpty ? nil : response.status.reasonPhrase
                return .http(status: status, reason: reason, operationID: clientError.operationID)
            }
            return .unknown(description: clientError.causeDescription)
        }
        return .unknown(description: String(describing: error))
    }

    private struct OperationOutcome<Value> {
        var value: Value
        var statusCode: Int
    }
}

public protocol AnimationServiceClientMonitor: Sendable {
    func client(_ client: AnimationServiceClient, willSend request: AnimationServiceClient.RequestMetadata)
    func client(_ client: AnimationServiceClient, didComplete request: AnimationServiceClient.RequestMetadata, result: AnimationServiceClient.RequestResult)
}

public extension AnimationServiceClientMonitor {
    func client(_ client: AnimationServiceClient, willSend request: AnimationServiceClient.RequestMetadata) {}
    func client(
        _ client: AnimationServiceClient,
        didComplete request: AnimationServiceClient.RequestMetadata,
        result: AnimationServiceClient.RequestResult
    ) {}
}
