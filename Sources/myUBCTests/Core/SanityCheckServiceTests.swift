@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

final class SanityCheckServiceTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    func testSanityCheckServiceParsesVersionPayload() async throws {
        let payload = """
        {
          "staging": false,
          "version": "99.0",
          "inreview": "0.0",
          "notice": {
            "title": "Ongoing Issue",
            "detail": "Calendar incident",
            "link": "https://example.com/notice",
            "skip": ["2.2.1"]
          }
        }
        """
        let client = makeNetworkClient(responseData: Data(payload.utf8))
        let service = SanityCheckService(client: client)
        let result = await service.fetch()
        let value = try XCTUnwrap(result.successValue())
        XCTAssertFalse(value.isStaging)
        XCTAssertEqual(value.notice?.title, "Ongoing Issue")
        XCTAssertEqual(value.notice?.detail, "Calendar incident")
        XCTAssertEqual(value.notice?.link, "https://example.com/notice")
        XCTAssertEqual(value.notice?.skipVersions, ["2.2.1"])
    }

    func testSanityCheckServiceHandlesMalformedPayload() async {
        let client = makeNetworkClient(responseData: Data("{}".utf8))
        let service = SanityCheckService(client: client)
        let result = await service.fetch()

        guard case let .success(value) = result else {
            return XCTFail("Expected fallback success result")
        }
        XCTAssertTrue(value.isStaging)
        XCTAssertFalse(value.isNewVersionAvailable)
    }

    func testSanityCheckServiceMapsNetworkErrors() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        URLProtocolStub.handler = { _ in throw URLError(.notConnectedToInternet) }
        let client = NetworkClient(session: URLSession(configuration: config))
        let service = SanityCheckService(client: client)

        let result = await service.fetch()
        guard case let .failure(error) = result else {
            return XCTFail("Expected network failure")
        }
        guard case .network = error else {
            return XCTFail("Expected AppError.network")
        }
    }

    private func makeNetworkClient(responseData: Data) -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            return URLProtocolStub.successResponse(for: url, data: responseData)
        }
        return NetworkClient(session: URLSession(configuration: config))
    }
}
