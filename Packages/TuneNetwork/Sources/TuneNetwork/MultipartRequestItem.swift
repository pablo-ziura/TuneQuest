import Foundation

public struct MultipartRequestItem {
    let data: Data
    let contentDisposition: String
    let contentType: String
}

extension [MultipartRequestItem] {
    func asMultipartData(boundary: String) -> Data {
        let body = NSMutableData()

        self.forEach { item in
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; \(item.contentDisposition)\r\n")
            body.appendString("Content-Type: \(item.contentType)\r\n\r\n")
            body.append(item.data)
            body.appendString("\r\n")
        }

        body.appendString("--\(boundary)--\r\n")

        return body as Data
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
