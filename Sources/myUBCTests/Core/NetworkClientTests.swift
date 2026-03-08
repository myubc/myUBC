@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

final class NetworkClientTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    func testInjectsAcceptLanguageHeaderWhenMissing() async throws {
        let client = makeNetworkClient()
        let url = try XCTUnwrap(URL(string: "https://example.com/test"))
        URLProtocolStub.handler = { request in
            guard let requestURL = request.url else {
                throw URLError(.badURL)
            }
            let header = request.value(forHTTPHeaderField: "Accept-Language")
            XCTAssertNotNil(header)
            XCTAssertFalse((header ?? "").isEmpty)
            return URLProtocolStub.successResponse(for: requestURL, data: Data("ok".utf8))
        }

        let data = try await client.data(from: url, policy: .noRetry)
        XCTAssertEqual(String(bytes: data, encoding: .utf8), "ok")
    }

    func testPreservesAcceptLanguageHeaderWhenProvided() async throws {
        let client = makeNetworkClient()
        var request = try URLRequest(url: XCTUnwrap(URL(string: "https://example.com/custom")))
        request.setValue("en-CA", forHTTPHeaderField: "Accept-Language")

        URLProtocolStub.handler = { request in
            guard let requestURL = request.url else {
                throw URLError(.badURL)
            }
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "en-CA")
            return URLProtocolStub.successResponse(for: requestURL, data: Data("ok".utf8))
        }

        _ = try await client.data(for: request, policy: .noRetry)
    }

    func testRetriesForServerFailures() async throws {
        let client = makeNetworkClient()
        let lock = NSLock()
        var attempts = 0

        URLProtocolStub.handler = { request in
            guard let requestURL = request.url else {
                throw URLError(.badURL)
            }
            lock.lock()
            attempts += 1
            let currentAttempt = attempts
            lock.unlock()

            if currentAttempt < 3 {
                return URLProtocolStub.httpResponse(for: requestURL, statusCode: 503, data: Data("retry".utf8))
            }
            return URLProtocolStub.successResponse(for: requestURL, data: Data("done".utf8))
        }

        let policy = RetryPolicy(maxRetries: 2, baseDelay: 0, maxDelay: 0)
        let url = try XCTUnwrap(URL(string: "https://example.com/retry"))
        let data = try await client.data(from: url, policy: policy)

        XCTAssertEqual(String(bytes: data, encoding: .utf8), "done")
        XCTAssertEqual(attempts, 3)
    }

    func testDoesNotRetryForClientFailure() async throws {
        let client = makeNetworkClient()
        let lock = NSLock()
        var attempts = 0

        URLProtocolStub.handler = { request in
            guard let requestURL = request.url else {
                throw URLError(.badURL)
            }
            lock.lock()
            attempts += 1
            lock.unlock()
            return URLProtocolStub.httpResponse(for: requestURL, statusCode: 404, data: Data("missing".utf8))
        }

        do {
            let url = try XCTUnwrap(URL(string: "https://example.com/not-found"))
            _ = try await client.data(
                from: url,
                policy: RetryPolicy(maxRetries: 3, baseDelay: 0, maxDelay: 0)
            )
            XCTFail("Expected HTTP status error")
        } catch let error as NetworkError {
            guard case let .httpStatus(status) = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            XCTAssertEqual(status, 404)
            XCTAssertEqual(attempts, 1)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testThrowsEmptyDataFor200Response() async throws {
        let client = makeNetworkClient()
        URLProtocolStub.handler = { request in
            guard let requestURL = request.url else {
                throw URLError(.badURL)
            }
            return URLProtocolStub.successResponse(for: requestURL, data: Data())
        }

        do {
            let url = try XCTUnwrap(URL(string: "https://example.com/empty"))
            _ = try await client.data(from: url, policy: .noRetry)
            XCTFail("Expected empty data error")
        } catch let error as NetworkError {
            guard case .emptyData = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    private func makeNetworkClient() -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        return NetworkClient(session: session)
    }
}
