@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

final class ServiceFlowTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    func testFoodServiceCachesAndAvoidsDuplicateRequests() async throws {
        let cache = CacheStore()
        await cache.invalidate(key: CachePolicy.food.key)

        let fixture = try fixtureData("feed_me")
        let client = makeNetworkClient()
        let service = FoodService(client: client, cache: cache)

        let lock = NSLock()
        var requestCount = 0
        URLProtocolStub.handler = { request in
            guard let requestURL = request.url else {
                throw URLError(.badURL)
            }
            lock.lock()
            requestCount += 1
            lock.unlock()
            XCTAssertEqual(request.url?.absoluteString, Constants.foodLink)
            return URLProtocolStub.successResponse(for: requestURL, data: fixture)
        }

        let first = await service.fetchLocations(forceRefresh: false)
        let firstValue = try XCTUnwrap(first.successValue())
        XCTAssertFalse(firstValue.isFromCache)
        XCTAssertFalse(firstValue.value.isEmpty)

        let second = await service.fetchLocations(forceRefresh: false)
        let secondValue = try XCTUnwrap(second.successValue())
        XCTAssertTrue(secondValue.isFromCache)
        XCTAssertEqual(requestCount, 1)
    }

    func testFoodServiceFallsBackToCacheOnOfflineRefresh() async throws {
        let cache = CacheStore()
        await cache.invalidate(key: CachePolicy.food.key)
        let cached = [FoodLocation(name: "Cached Place", isOpen: true, statusText: "Open")]
        await cache.save(cached, key: CachePolicy.food.key)

        let client = makeNetworkClient(error: URLError(.notConnectedToInternet))
        let service = FoodService(client: client, cache: cache)

        let result = await service.fetchLocations(forceRefresh: true)
        let value = try XCTUnwrap(result.successValue())
        XCTAssertTrue(value.isFromCache)
        XCTAssertTrue(value.hadNetworkError)
        XCTAssertEqual(value.value.first?.name, "Cached Place")

        guard let networkError = value.networkError else {
            return XCTFail("Expected mapped network error")
        }
        guard case .offline = networkError else {
            return XCTFail("Expected offline error")
        }
    }

    func testFoodDetailServiceCachesByURLAndAvoidsDuplicateRequests() async throws {
        let cache = CacheStore()
        let detailURL = "https://food.ubc.ca/places/test-cafe/"
        await cache.invalidate(key: foodDetailCacheKey(for: detailURL))

        let fixture = try fixtureData("food_detail")
        let client = makeNetworkClient()
        let service = FoodDetailService(client: client, cache: cache)

        let lock = NSLock()
        var requestCount = 0
        URLProtocolStub.handler = { request in
            guard let requestURL = request.url else {
                throw URLError(.badURL)
            }
            lock.lock()
            requestCount += 1
            lock.unlock()
            return URLProtocolStub.successResponse(for: requestURL, data: fixture)
        }

        let first = await service.fetchDetails(url: detailURL, forceRefresh: false)
        let firstValue = try XCTUnwrap(first.successValue())
        XCTAssertFalse(firstValue.isFromCache)
        XCTAssertFalse(firstValue.value.description.isEmpty)

        let second = await service.fetchDetails(url: detailURL, forceRefresh: false)
        let secondValue = try XCTUnwrap(second.successValue())
        XCTAssertTrue(secondValue.isFromCache)
        XCTAssertEqual(requestCount, 1)
    }

    func testFoodDetailServiceRefreshFallsBackToCacheOnNetworkFailure() async throws {
        let cache = CacheStore()
        let detailURL = "https://food.ubc.ca/places/fallback-cafe/"
        let cacheKey = foodDetailCacheKey(for: detailURL)
        await cache.invalidate(key: cacheKey)

        let cached = FoodDetailItem(description: "Cached summary", carryover: false, ubccard: true, mealplan: true, images: [])
        await cache.save(cached, key: cacheKey)

        let client = makeNetworkClient(error: URLError(.timedOut))
        let service = FoodDetailService(client: client, cache: cache)

        let result = await service.fetchDetails(url: detailURL, forceRefresh: true)
        let value = try XCTUnwrap(result.successValue())
        XCTAssertTrue(value.isFromCache)
        XCTAssertTrue(value.hadNetworkError)
        XCTAssertEqual(value.value.description, "Cached summary")
    }

    private func makeNetworkClient(error: Error? = nil) -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)

        if let error {
            URLProtocolStub.handler = { _ in
                throw error
            }
        }

        return NetworkClient(session: session)
    }

    private func fixtureData(_ name: String) throws -> Data {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(
            bundle.url(forResource: name, withExtension: "html", subdirectory: "Fixtures")
                ?? bundle.url(forResource: name, withExtension: "html")
        )
        return try Data(contentsOf: url)
    }

    private func foodDetailCacheKey(for urlString: String) -> String {
        let suffix = Data(urlString.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return CachePolicy.foodDetail.key + "." + suffix
    }
}
