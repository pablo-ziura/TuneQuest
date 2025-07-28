import Foundation

public protocol NetworkClientProtocol: Sendable {
    func get<O: Decodable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?
    ) async throws -> O

    func post<I: Encodable, O: Decodable>(
        endpoint: String,
        params: [String: String]?,
        headers: [String: String]?,
        data: I
    ) async throws -> O

    func post<O: Decodable>(
        url: URL,
        body: Data
    ) async throws -> O

    func postFiles<O: Decodable>(
        endpoint: APIEndpointProtocol,
        params: [String: String]?,
        headers: [String: String]?,
        files: [Data]
    ) async throws -> O
}
