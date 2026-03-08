@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

final class CacheAndConfigTests: XCTestCase {
    func testCachePolicyExpiryBoundaries() {
        let policy = CachePolicy(key: "test", ttl: 60, maxStale: 120)
        let fresh = Date().addingTimeInterval(-30)
        let stale = Date().addingTimeInterval(-90)
        let tooStale = Date().addingTimeInterval(-180)

        XCTAssertFalse(policy.isExpired(since: fresh))
        XCTAssertTrue(policy.isExpired(since: stale))
        XCTAssertFalse(policy.isTooStale(since: stale))
        XCTAssertTrue(policy.isTooStale(since: tooStale))
    }

    func testCacheStoreSaveLoadInvalidateAndLoadEntry() async {
        let cache = CacheStore()
        let key = "cache.test.locations"
        await cache.invalidate(key: key)

        let value = [FoodLocation(name: "A", isOpen: true, statusText: "Open")]
        await cache.save(value, key: key)

        let loaded = await cache.load([FoodLocation].self, key: key, maxAge: 60)
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.name, "A")

        let policy = CachePolicy(key: key, ttl: 60, maxStale: 300)
        let entry = await cache.loadEntry([FoodLocation].self, policy: policy)
        XCTAssertEqual(entry?.value.first?.statusText, "Open")
        XCTAssertEqual(entry?.isStale, false)

        await cache.invalidate(key: key)
        let afterInvalidate = await cache.load([FoodLocation].self, key: key, maxAge: 60)
        XCTAssertNil(afterInvalidate)
    }

    func testCacheStorePruneRemovesOldEntriesByModificationDate() async throws {
        let cache = CacheStore()
        let key = "cache.test.prune"
        await cache.invalidate(key: key)
        await cache.save(["old"], key: key)

        let cacheRoot = try XCTUnwrap(
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("myUBC.cache", isDirectory: true)
        )
        let fileURL = cacheRoot.appendingPathComponent(key + ".json")
        let oldDate = Date(timeIntervalSinceNow: -3600)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: fileURL.path)

        await cache.prune(maxAge: 60)
        let data = try? Data(contentsOf: fileURL)
        XCTAssertNil(data)
    }

    func testCacheBannerOfflineIncludesMessage() {
        let banner = CacheBanner.from(
            lastUpdated: Date().addingTimeInterval(-120),
            isStale: false,
            isFromCache: true,
            networkError: .offline
        )
        XCTAssertEqual(banner?.style, .offline)
        XCTAssertTrue((banner?.message.isEmpty == false))
    }

    func testCacheBannerStaleAndInfoModes() {
        let staleBanner = CacheBanner.from(
            lastUpdated: Date().addingTimeInterval(-1800),
            isStale: true,
            isFromCache: false,
            networkError: nil
        )
        XCTAssertEqual(staleBanner?.style, .stale)

        let infoBanner = CacheBanner.from(
            lastUpdated: Date().addingTimeInterval(-1800),
            isStale: false,
            isFromCache: true,
            networkError: nil
        )
        XCTAssertEqual(infoBanner?.style, .info)

        let noBanner = CacheBanner.from(lastUpdated: nil, isStale: false, isFromCache: false, networkError: nil)
        XCTAssertNil(noBanner)
    }

    func testFoodCatalogAndPlaceCatalogLoad() {
        let items = FoodCatalog.load()
        let places = FoodPlaceCatalog.loadDefaults()
        let dict = FoodPlaceCatalog.asDictionary()

        XCTAssertFalse(items.isEmpty)
        XCTAssertFalse(places.isEmpty)
        XCTAssertFalse(dict.isEmpty)
        XCTAssertEqual(places.first?.sortOrder, places.map(\.sortOrder).min())
    }

    func testFoodStatusRulesDefaultAndMainLoad() {
        let defaults = FoodStatusRules.defaultRules
        XCTAssertFalse(defaults.openClassTokens.isEmpty)
        XCTAssertFalse(defaults.closedClassTokens.isEmpty)

        let loaded = FoodStatusRules.load()
        XCTAssertFalse(loaded.statusContainerSelectors.isEmpty)
        XCTAssertFalse(loaded.statusTextSelectors.isEmpty)
    }

    func testCalendarSourceBuildsExpectedAcademicYearURL() {
        let springURL = CalendarSource.sourceURL(for:
                                                    DateComponents(calendar:
                                                                    Calendar(identifier: .gregorian),
                                                                   year: 2026, month: 2, day: 1).date ??
                                                 Date()).absoluteString
        let fallURL = CalendarSource.sourceURL(for: DateComponents(calendar: Calendar(identifier: .gregorian),
                                                                   year: 2025, month: 10, day: 1).date ??
                                               Date()).absoluteString

        XCTAssertTrue(springURL.contains("academic-year-"))
        XCTAssertTrue(fallURL.contains("academic-year-"))
        XCTAssertTrue(springURL.hasSuffix("/all-months"))
        XCTAssertTrue(fallURL.hasSuffix("/all-months"))
    }
}
