import Foundation

public protocol NetworkClientProtocol: Sendable {
    func get<O: Decodable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?
    ) async throws -> O

    func post<O: Decodable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?,
        body: Data
    ) async throws -> O
}

public extension NetworkClientProtocol {
    func post<I: Encodable, O: Decodable>(
        endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String]? = nil,
        data: I,
        encoder: JSONEncoder = .init()
    ) async throws -> O {
        let encoded = try encoder.encode(data)
        return try await post(
            endpoint: endpoint,
            params: params,
            headers: headers,
            body: encoded
        )
    }
}
