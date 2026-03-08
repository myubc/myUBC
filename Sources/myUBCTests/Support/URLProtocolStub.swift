import Foundation

final class URLProtocolStub: URLProtocol {
    private static let lock = NSLock()
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        handler = nil
    }

    static func successResponse(for url: URL, data: Data) -> (HTTPURLResponse, Data) {
        httpResponse(for: url, statusCode: 200, data: data)
    }

    static func httpResponse(for url: URL, statusCode: Int, data: Data) -> (HTTPURLResponse, Data) {
        guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) else {
            preconditionFailure("Failed to build HTTPURLResponse for \(url)")
        }
        return (response, data)
    }

    // swiftlint:disable:next static_over_final_class
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    // swiftlint:disable:next static_over_final_class
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        URLProtocolStub.lock.lock()
        let handler = URLProtocolStub.handler
        URLProtocolStub.lock.unlock()

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
