import Foundation

public final class URLSessionNetworkClient: NetworkClientProtocol {
    private let baseUrl: String
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    struct HeaderKeys {
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
    }

    public init(
        baseUrl: String,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
    ) {
        self.baseUrl = baseUrl
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    public func get<O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?
    ) async throws -> O {
        try await performRequest(
            httpMethod: .get,
            endpoint: endpoint,
            headers: headers,
            params: params
        )
    }

    public func post<I: Encodable, O: Decodable & Sendable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?,
        data: I
    ) async throws -> O {
        let body = try encoder.encode(data)

        return try await performRequest(
            httpMethod: .post,
            endpoint: endpoint,
            body: body,
            headers: headers,
            params: params
        )
    }

    public func post<O: Decodable & Sendable>(
        url: URL,
        body: Data
    ) async throws -> O {
        return try await performRequest(
            httpMethod: .post,
            url: url,
            body: body
        )
    }

    
    public func postFiles<O: Decodable & Sendable>(
        params: [String: String]?,
        headers: [String: String]?,
        files: [Data]
    ) async throws -> O {
        guard !files.isEmpty else {
            throw NetworkError.noFilesProvided
        }

        let boundary = UUID().uuidString

        var requestHeaders = [String: String]()
        headers?.forEach { requestHeaders[$0.key] = $0.value }
        requestHeaders[HeaderKeys.contentType] = "multipart/form-data; boundary=\(boundary)"

        let multipartRequestItems = files.map {
            MultipartRequestItem(
                data: $0,
                contentDisposition: "name=\"\"; filename=\"\"",
                contentType: "application/octet-stream"
            )
        }

        return try await performRequest(
            httpMethod: .post,
            endpoint: endpoint,
            body: multipartRequestItems.asMultipartData(boundary: boundary),
            headers: requestHeaders,
            params: params,
        )
    }
}

// MARK: - Utility Methods

extension URLSessionNetworkClient {
    func performRequest<O: Decodable & Sendable>(
        httpMethod: HTTPMethod,
        endpoint: String,
        body: Data? = nil,
        headers: [String: String]? = nil,
        params: [String: String]? = nil
    ) async throws -> O {
        let url = try buildURL(from: endpoint, with: params)

        let urlRequest = try await buildURLRequest(
            url: url,
            httpMethod: httpMethod,
            body: body,
            headers: headers
        )

        let data = try await performRequestCommon(
            urlRequest: urlRequest
        )

        return try decodeOrEmpty(data, responseVersion: responseVersion)
    }

    func buildURL(
        from endpoint: String,
        with params: [String: String]? = nil
    ) throws -> URL {
        let urlString = "\(baseUrl)/\(endpoint)"
        var components = URLComponents(string: urlString)
        let queryItems = params?.compactMap { key, value -> URLQueryItem? in
            if !value.isEmpty {
                return URLQueryItem(name: key, value: value)
            }
            return nil
        }

        components?.queryItems = queryItems?.isEmpty == true ? nil : queryItems
        let finalUrlString = components?.url?.absoluteString ?? urlString
        guard let url = URL(string: finalUrlString) else {
            throw NetworkError.wrongURL
        }
        return url
    }
}

// MARK: - Private Methods

private extension URLSessionNetworkClient {
    func performRequest<O: Decodable & Sendable>(
        httpMethod: HTTPMethod,
        url: URL,
        body: Data? = nil
    ) async throws -> O {
        let urlRequest = try await buildURLRequest(
            url: url,
            httpMethod: httpMethod,
            body: body,
            headers: nil
        )

        let data = try await performRequest(
            urlRequest: urlRequest,
        )

        return try decodeOrEmpty(data, responseVersion: nil)
    }

    func performRequestCommon(
        urlRequest: URLRequest,
        responseVersion: APIResponseVersion?
    ) async throws -> Data {
        let url = urlRequest.url?.absoluteString ?? "?"
        let httpMethod = urlRequest.httpMethod ?? "?"
        print("🛜 Request: \(httpMethod) - \(url)")

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noHTTPURLResponse
            }

            print("🛠 Response to \(url) with status code \(httpResponse.statusCode): \(httpResponse.debugDescription)")

            switch httpResponse.statusCode {
            case 200 ... 299:
                return data
            case 401:
                throw NetworkError.unauthorized
            default:
                throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
            }
        } catch {
            print("🛑 Error in request \(url): \(error)")
            throw error
        }
    }

    private func handleSuccessResponse<O: Decodable>(
        data: Data,
        statusCode: Int,
        headers: [AnyHashable: Any]
    ) throws -> O {
        if data.isEmpty {
            if O.self == EmptyResponse.self {
                guard let emptyValue = EmptyResponse() as? O else {
                    throw NetworkError.unexpectedType
                }

                return data

            }
            throw NetworkError.emptyResponse
        }

    }

    func buildURLRequest(
        url: URL,
        httpMethod: HTTPMethod,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> URLRequest {

        var requestUrl = URLRequest(url: url)

        requestUrl.httpMethod = httpMethod.rawValue
        requestUrl.httpBody = body

        var requestHeaders = [String: String]()

        headers?.forEach { requestHeaders[$0.key] = $0.value }
        if requestHeaders[HeaderKeys.contentType] == nil {
            requestHeaders[HeaderKeys.contentType] = "application/json"
        }

        requestHeaders.forEach { requestUrl.addValue($0.value, forHTTPHeaderField: $0.key) }

        return requestUrl
    }
}
