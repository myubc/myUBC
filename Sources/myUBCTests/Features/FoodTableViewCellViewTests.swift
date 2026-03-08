@testable import myUBC
import XCTest

@MainActor
final class FoodTableViewCellViewTests: XCTestCase, ViewFixtureLoading {
    func testOpenFoodCellShowsOpenStateAndAddress() throws {
        let cell: FoodTableViewCell = try loadViewFromNib(named: FoodTableViewCell.nib)
        cell.setup(
            model: FoodLocation(
                name: "Starbucks @ UBC",
                isOpen: true,
                statusText: "Open until 5:00 PM",
                slug: "starbucks",
                url: "https://example.com/starbucks",
                address: "6138 Student Union Blvd",
                rating: 4
            )
        )

        XCTAssertEqual(cell.name.text, "Starbucks @ UBC")
        XCTAssertEqual(cell.today.text, "Open")
        XCTAssertEqual(cell.hours.text, "Open until 5:00 PM")
        XCTAssertEqual(cell.location.text, "6138 Student Union Blvd")
        XCTAssertFalse(cell.location.isHidden)
        XCTAssertNotNil(cell.logo.image)
    }

    func testClosedFoodCellHidesEmptyAddress() throws {
        let cell: FoodTableViewCell = try loadViewFromNib(named: FoodTableViewCell.nib)
        cell.setup(
            model: FoodLocation(
                name: "Tim Hortons",
                isOpen: false,
                statusText: "Closed",
                slug: "tim-hortons",
                url: "https://example.com/tim",
                address: "",
                rating: 3
            )
        )

        XCTAssertEqual(cell.today.text, "Closed")
        XCTAssertEqual(cell.hours.text, "Closed")
        XCTAssertNil(cell.location.text)
        XCTAssertTrue(cell.location.isHidden)
        XCTAssertEqual(cell.statusIcon.tintColor, #colorLiteral(red: 0.8588235294, green: 0.3607843137, blue: 0, alpha: 1))
    }
}
