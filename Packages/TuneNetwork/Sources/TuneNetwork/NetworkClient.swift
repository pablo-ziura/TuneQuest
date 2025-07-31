import Foundation
import OSLog

public final class NetworkClient: NetworkClientProtocol {
    private let baseUrl: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger: Logger

    public init(
        baseUrl: String,
        session: URLSession = .shared,
        decoder: JSONDecoder = .init(),
        logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "NetworkClient", category: "Network")
    ) {
        self.baseUrl = baseUrl
        self.session = session
        self.decoder = decoder
        self.logger = logger
    }

    public func get<O: Decodable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil
    ) async throws -> O {
        logger.debug("→ GET request to \(endpoint, privacy: .public) params: \(params ?? [:], privacy: .private)")
        return try await request(
            .get,
            endpoint: endpoint,
            params: params,
            headers: headers,
            body: nil
        )
    }

    public func post<O: Decodable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Data
    ) async throws -> O {
        logger.debug("→ POST request to \(endpoint, privacy: .public) params: \(params ?? [:], privacy: .private) bodyLength: \(body.count, privacy: .public)")
        return try await request(
            .post,
            endpoint: endpoint,
            params: params,
            headers: headers,
            body: body
        )
    }

    private func request<O: Decodable>(
        _ method: HTTPMethod,
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?,
        body: Data?
    ) async throws -> O {
        let url = try buildURL(from: endpoint, params: params)
        logger.debug("Built URL: \(url.absoluteString, privacy: .public)")
        return try await rawRequest(method, url: url, headers: headers, body: body)
    }

    private func rawRequest<O: Decodable>(
        _ method: HTTPMethod,
        url: URL,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> O {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        var allHeaders = headers ?? [:]
        if allHeaders["Content-Type"] == nil {
            allHeaders["Content-Type"] = "application/json"
        }
        allHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        logger.debug("Sending \(method.rawValue, privacy: .public) to \(url.absoluteString, privacy: .public) headers: \(allHeaders, privacy: .private) bodyLength: \(body?.count ?? 0, privacy: .public)")

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.error("Network error: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            logger.error("No HTTPURLResponse received")
            throw NetworkError.noHTTPURLResponse
        }

        logger.debug("Received status: \(http.statusCode, privacy: .public) dataLength: \(data.count, privacy: .public)")

        switch http.statusCode {
        case 200 ..< 300:
            break
        case 401:
            logger.error("Unauthorized (401)")
            throw NetworkError.unauthorized
        default:
            logger.error("Unexpected status code: \(http.statusCode, privacy: .public)")
            throw NetworkError.unexpectedStatusCode(http.statusCode)
        }

        do {
            let decoded = try decoder.decode(O.self, from: data)

            if let jsonString = String(data: data, encoding: .utf8) {
                logger.info("📥 JSON Received:\n\(jsonString, privacy: .public) ✨")
            }

            return decoded
        } catch {
            let bodyString = String(data: data, encoding: .utf8) ?? "<binary>"
            logger.error("Decoding error: \(error.localizedDescription, privacy: .public) Raw body: \(bodyString, privacy: .private)")
            throw NetworkError.errorWithMessage("Decoding error: \(error)")
        }
    }

    private func buildURL(from endpoint: String, params: [String: String]?) throws -> URL {
        var components = URLComponents(string: "\(baseUrl)/\(endpoint)")
        if let params, !params.isEmpty {
            components?.queryItems = params
                .filter { !$0.value.isEmpty }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else {
            logger.error("Malformed URL for endpoint: \(endpoint, privacy: .public)")
            throw NetworkError.wrongURL
        }
        return url
    }
}
