@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

final class ServiceCoverageTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    func testParkingServiceFetchAndCacheFallback() async throws {
        let cache = CacheStore()
        await cache.invalidate(key: CachePolicy.parking.key)
        let service = try ParkingService(client: makeNetworkClient(data: fixtureData("parking")), cache: cache)

        let first = await service.fetchParking(forceRefresh: true)
        let firstValue = try XCTUnwrap(first.successValue())
        XCTAssertFalse(firstValue.value.isEmpty)
        XCTAssertFalse(firstValue.isFromCache)

        let second = await service.fetchParking(forceRefresh: false)
        let secondValue = try XCTUnwrap(second.successValue())
        XCTAssertTrue(secondValue.isFromCache)

        URLProtocolStub.handler = { _ in throw URLError(.timedOut) }
        let fallback = await service.fetchParking(forceRefresh: true)
        let fallbackValue = try XCTUnwrap(fallback.successValue())
        XCTAssertTrue(fallbackValue.isFromCache)
        XCTAssertTrue(fallbackValue.hadNetworkError)
    }

    func testInfoServiceFetchAndFailureFallback() async throws {
        let cache = CacheStore()
        await cache.invalidate(key: CachePolicy.info.key)
        let service = try InfoService(client: makeNetworkClient(data: fixtureData("campus_notifications")), cache: cache)

        let first = await service.fetchNotifications(forceRefresh: true)
        let firstValue = try XCTUnwrap(first.successValue())
        XCTAssertEqual(firstValue.value.count, 1)

        URLProtocolStub.handler = { _ in throw URLError(.notConnectedToInternet) }
        let fallback = await service.fetchNotifications(forceRefresh: true)
        let fallbackValue = try XCTUnwrap(fallback.successValue())
        XCTAssertTrue(fallbackValue.isFromCache)
        guard case .offline = fallbackValue.networkError else {
            return XCTFail("Expected offline error")
        }
    }

    func testCalendarServiceSuccessAndEmptyParsingFailure() async throws {
        let cache = CacheStore()
        let calendarFixture = try fixtureData("calendar")
        let calendarHTML = try XCTUnwrap(String(bytes: calendarFixture, encoding: .utf8))
        let eventsFromFixture = try CalendarParser.parse(html: calendarHTML)
        let visibleMonth = try XCTUnwrap(eventsFromFixture.first?.date)
        let service = CalendarService(client: makeNetworkClient(data: calendarFixture), cache: cache)

        let success = await service.fetchMonth(visibleMonth, forceRefresh: true)
        let successValue = try XCTUnwrap(success.successValue())
        XCTAssertFalse(successValue.value.isEmpty)

        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            return URLProtocolStub.successResponse(for: url, data: Data("<html><body>none</body></html>".utf8))
        }
        let fail = await service.fetchMonth(visibleMonth, forceRefresh: true)
        guard case let .failure(error) = fail else {
            return XCTFail("Expected parsing failure")
        }
        guard case .parsing = error else {
            return XCTFail("Expected parsing error")
        }
    }

    func testLibraryServiceNetworkAndFallbackBranches() async throws {
        let cache = CacheStore()
        await cache.invalidate(key: CachePolicy.library.key)
        let service = try LibraryService(client: makeNetworkClient(data: fixtureData("library")), cache: cache)

        let first = await service.fetchLibrary(forceRefresh: true)
        let firstValue = try XCTUnwrap(first.successValue())
        XCTAssertFalse(firstValue.isFromCache)
        XCTAssertFalse(firstValue.value.iphones1.isEmpty)

        URLProtocolStub.handler = { _ in throw URLError(.cannotFindHost) }
        let fallback = await service.fetchLibrary(forceRefresh: true)
        let fallbackValue = try XCTUnwrap(fallback.successValue())
        XCTAssertTrue(fallbackValue.isFromCache)
        XCTAssertTrue(fallbackValue.hadNetworkError)
    }

    private func makeNetworkClient(data: Data) -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            return URLProtocolStub.successResponse(for: url, data: data)
        }
        return NetworkClient(session: URLSession(configuration: config))
    }

    private func fixtureData(_ name: String) throws -> Data {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(
            bundle.url(forResource: name, withExtension: "html", subdirectory: "Fixtures")
                ?? bundle.url(forResource: name, withExtension: "html")
        )
        return try Data(contentsOf: url)
    }
}
