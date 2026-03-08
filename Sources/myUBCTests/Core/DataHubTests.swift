@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

final class DataHubTests: XCTestCase {
    func testLoadLandingSnapshotDeduplicatesConcurrentRequests() async {
        let food = TestDoubles.CountingFoodService()
        let parking = TestDoubles.CountingParkingService()
        let info = TestDoubles.CountingInfoService()
        let library = TestDoubles.CountingLibraryService()
        let calendar = TestDoubles.CountingCalendarService()
        let hub = DataHub(food: food, parking: parking, info: info, library: library, calendar: calendar)

        async let first = hub.loadLandingSnapshot()
        async let second = hub.loadLandingSnapshot()
        _ = await(first, second)

        let foodCount = await food.count
        let parkingCount = await parking.count
        let infoCount = await info.count
        let libraryCount = await library.count
        let calendarCount = await calendar.count

        XCTAssertEqual(foodCount, 1)
        XCTAssertEqual(parkingCount, 1)
        XCTAssertEqual(infoCount, 1)
        XCTAssertEqual(libraryCount, 1)
        XCTAssertEqual(calendarCount, 1)
    }

    func testRefreshAllMapsFailuresToFalseStatus() async {
        let food = TestDoubles.CountingFoodService()
        let parking = TestDoubles.CountingParkingService()
        let info = TestDoubles.CountingInfoService()
        let library = TestDoubles.CountingLibraryService()
        let calendar = TestDoubles.FailingCalendarService()
        let hub = DataHub(food: food, parking: parking, info: info, library: library, calendar: calendar)

        let summary = await hub.refreshAll()
        XCTAssertTrue(summary.food)
        XCTAssertTrue(summary.parking)
        XCTAssertTrue(summary.info)
        XCTAssertTrue(summary.library)
        XCTAssertFalse(summary.calendar)
    }
}
