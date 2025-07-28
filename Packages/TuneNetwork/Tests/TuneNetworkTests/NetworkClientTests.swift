import Foundation
import Testing
@testable import TuneNetwork

@MainActor
final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    static var stub: (data: Data?, response: URLResponse?, error: Error?)?
    static var lastRequest: URLRequest?
    static var requestBody: Data?

    static func configure(data: Data?, statusCode: Int) {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        stub = (data, response, nil)
        lastRequest = nil
        requestBody = nil
    }

    static func configureError(_ error: Error) {
        stub = (nil, nil, error)
        lastRequest = nil
        requestBody = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Task { @MainActor in
            Self.lastRequest = request
        }

        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1<<10
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            Task { @MainActor in
                Self.requestBody = data
            }
        } else {
            Task { @MainActor in
                Self.requestBody = request.httpBody
            }
        }

        Task { @MainActor in
            if let stub = Self.stub {
                if let response = stub.response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = stub.data {
                    client?.urlProtocol(self, didLoad: data)
                }
                if let error = stub.error {
                    client?.urlProtocol(self, didFailWithError: error)
                } else {
                    client?.urlProtocolDidFinishLoading(self)
                }
            }
        }
    }

    override func stopLoading() {}
}

private struct MockDecodable: Codable, Equatable, Sendable {
    let value: String
}

@Suite("URLSessionNetworkClient")
struct URLSessionNetworkClientTests: @unchecked Sendable {

    // Helpers ---------------------------------------------------------------

    /// Returns a client wired to the `URLProtocolStub`.
    private func makeSUT(baseUrl: String = "https://api.example.com") -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        return NetworkClient(baseUrl: baseUrl, session: session)
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - GET -----------------------------------------------------------

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
            #expect(false, "Expected unexpectedStatusCode, got \(String(describing: thrown))")
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
            return #expect(false, "No body captured")
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
            #expect(false, "Expected unexpectedStatusCode, got \(String(describing: thrown))")
        }
    }
}
