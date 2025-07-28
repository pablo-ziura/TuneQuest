import Foundation
import Testing
@testable import TuneNetwork

@Suite("NetworkClient", .serialized)
struct NetworkClientTests: @unchecked Sendable {
    private struct MockDecodable: Codable, Equatable, Sendable {
        let value: String
    }

    private func makeSUT(baseUrl: String = "https://api.example.com") -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        return NetworkClient(baseUrl: baseUrl, session: session)
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Test("GET • happy path decodes JSON")
    func getSuccess() async throws {
        let sut = makeSUT()
        let expected = MockDecodable(value: "OK")
        let json = try encoder.encode(expected)
        await URLProtocolStub.configure(data: json, statusCode: 200)

        let result: MockDecodable = try await sut.get(endpoint: "users/1")
        #expect(result == expected)
    }

    @Test("GET • 401 maps to NetworkError.unauthorized")
    func getUnauthorized() async {
        let sut = makeSUT()
        await URLProtocolStub.configure(data: Data(), statusCode: 401)

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "secure")
        } catch {
            thrown = error
        }
        #expect(thrown as? NetworkError == .unauthorized)
    }

    @Test("GET • unexpected status propagates")
    func getUnexpectedStatus() async {
        let sut = makeSUT()
        await URLProtocolStub.configure(data: Data(), statusCode: 500)

        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.get(endpoint: "boom")
        } catch {
            thrown = error
        }
        if case let NetworkError.unexpectedStatusCode(code)? = thrown {
            #expect(code == 500)
        } else {
            #expect(Bool(false), "Expected unexpectedStatusCode, got \(String(describing: thrown))")
        }
    }

    @Test("POST • happy path with body")
    func postSuccess() async throws {
        let sut = makeSUT()
        let expected = MockDecodable(value: "Created")
        let responseData = try encoder.encode(expected)
        await URLProtocolStub.configure(data: responseData, statusCode: 200)

        let requestData = try encoder.encode(MockDecodable(value: "Request"))
        let result: MockDecodable = try await sut.post(endpoint: "items", body: requestData)
        #expect(result == expected)
    }

    @Test("POST • body is sent as‑is")
    func postBodyCaptured() async throws {
        let sut = makeSUT()
        let expected = MockDecodable(value: "Echo")
        let responseData = try encoder.encode(expected)
        await URLProtocolStub.configure(data: responseData, statusCode: 200)

        let requestValue = MockDecodable(value: "Body")
        let body = try encoder.encode(requestValue)
        let _: MockDecodable = try await sut.post(endpoint: "echo", body: body)

        guard let sent = await URLProtocolStub.requestBody else {
            return #expect(Bool(false), "No body captured")
        }
        let decoded = try decoder.decode(MockDecodable.self, from: sent)
        #expect(decoded == requestValue)
    }

    @Test("POST • 500 maps to unexpectedStatusCode")
    func postUnexpectedStatus() async {
        let sut = makeSUT()
        await URLProtocolStub.configure(data: Data(), statusCode: 500)

        let body = Data("{}".utf8)
        var thrown: Error?
        do {
            let _: MockDecodable = try await sut.post(endpoint: "fail", body: body)
        } catch {
            thrown = error
        }
        if case let NetworkError.unexpectedStatusCode(code)? = thrown {
            #expect(code == 500)
        } else {
            #expect(Bool(false), "Expected unexpectedStatusCode, got \(String(describing: thrown))")
        }
    }
}
