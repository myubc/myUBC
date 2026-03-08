@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

final class ParserTests: XCTestCase {
    private func loadFixture(_ name: String) -> String {
        let bundle = Bundle(for: Self.self)
        let url = bundle.url(forResource: name, withExtension: "html", subdirectory: "Fixtures")
            ?? bundle.url(forResource: name, withExtension: "html")
        guard let url else {
            XCTFail("Missing fixture: \(name).html")
            return ""
        }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    func testFoodStatusParser() {
        let html = loadFixture("food_status_open")
        let location = FoodStatusParser.parse(html: html, name: "Test")
        XCTAssertTrue(location.isOpen)
        XCTAssertEqual(location.statusText, "Open til 5pm")
    }

    func testFoodDetailParser() throws {
        let html = loadFixture("food_detail")
        let item = try FoodDetailParser.parse(html: html)
        XCTAssertTrue(item.mealplan)
        XCTAssertTrue(item.ubccard)
        XCTAssertTrue(item.carryover)
        XCTAssertEqual(item.images.count, 0)
    }

    func testFoodDetailParserHeroCoffee() throws {
        let html = loadFixture("hero_coffee")
        let item = try FoodDetailParser.parse(html: html)
        XCTAssertTrue(item.mealplan)
        XCTAssertTrue(item.ubccard)
        XCTAssertFalse(item.carryover)
        XCTAssertTrue(!item.images.isEmpty)
    }

    func testParkingParser() throws {
        let html = loadFixture("parking")
        let lots = try ParkingParser.parse(html: html)
        XCTAssertEqual(lots.count, 1)
        XCTAssertEqual(lots.first?.lotName, .north)
        XCTAssertEqual(lots.first?.status.first, .good)
        XCTAssertEqual(lots.first?.status.last, .full)
    }

    func testCampusNotificationParser() throws {
        let html = loadFixture("campus_notifications")
        let items = try CampusNotificationParser.parse(html: html)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.notificationID, "n1")
    }

    func testCalendarParser() throws {
        let html = loadFixture("calendar")
        let events = try CalendarParser.parse(html: html)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.events.count, 2)
        XCTAssertTrue(events.first?.events.first?.isImportant ?? false)
    }

    func testLibraryParser() throws {
        let html = loadFixture("library")
        let equipment = try LibraryParser.parse(html: html, device: .IPhone1)
        XCTAssertEqual(equipment.count, 1)
        XCTAssertEqual(equipment.first?.total, "10")
    }

    /// Snapshot-style regression assertions for parser shape.
    func testParkingParserSnapshot() throws {
        let html = loadFixture("parking")
        let lots = try ParkingParser.parse(html: html)
        let snapshot = lots.map { "\($0.lotName.rawValue)|\($0.status.map(\.rawValue).joined(separator: ","))" }
            .joined(separator: "\n")
        XCTAssertEqual(snapshot, "North|good,full")
    }

    func testFoodDetailParserSnapshot() throws {
        let html = loadFixture("food_detail")
        let item = try FoodDetailParser.parse(html: html)
        let normalizedDescription = item.description
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let snapshot = [
            "mealplan=\(item.mealplan)",
            "ubccard=\(item.ubccard)",
            "carryover=\(item.carryover)",
            "images=\(item.images.count)",
            "descriptionPrefix=\(normalizedDescription.prefix(40))"
        ].joined(separator: "|")
        XCTAssertEqual(
            snapshot,
            "mealplan=true|ubccard=true|carryover=true|images=0|descriptionPrefix=Residence Meal Plans available Carryover"
        )
    }
}
