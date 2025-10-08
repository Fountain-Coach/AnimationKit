import Foundation
import OpenAPIURLSession
import OpenAPIRuntime

/// Thin façade for the generated OpenAPI client.
///
/// Note: At this stage, the façade does not directly reference
/// generated entrypoints to keep compilation independent of specific
/// symbol names. It provides a basic health endpoint using raw HTTP.
public struct AnimationServiceClient: Sendable {
    public struct Configuration: Sendable {
        public var baseURL: URL
        public var session: URLSession
        public init(baseURL: URL, session: URLSession = .shared) {
            self.baseURL = baseURL
            self.session = session
        }
    }

    private let config: Configuration

    public init(_ config: Configuration) {
        self.config = config
    }

    /// Simple health call until typed client wiring is added.
    public func health() async throws -> String {
        var request = URLRequest(url: config.baseURL.appendingPathComponent("/health"))
        request.httpMethod = "GET"
        let (data, response) = try await config.session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? String {
            return status
        }
        return "ok"
    }
}
