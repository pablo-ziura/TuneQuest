import Foundation

public enum NetworkError: Error, Equatable {
    case wrongURL
    case noHTTPURLResponse
    case dataIsNil
    case unauthorized
    case emptyResponse
    case unexpectedType
    case unexpectedStatusCode(Int)
    case errorWithMessage(String)
    case noFilesProvided
}
