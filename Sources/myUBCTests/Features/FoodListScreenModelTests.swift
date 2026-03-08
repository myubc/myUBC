@testable import myUBC
import XCTest

@MainActor
final class FoodListScreenModelTests: XCTestCase {
    func testVisibleFoodsRespectsOpenOnlyToggle() {
        let model = FoodListScreenModel()
        model.updateFoods([
            FoodLocation(name: "Open", isOpen: true, statusText: "Open"),
            FoodLocation(name: "Closed", isOpen: false, statusText: "Closed")
        ])

        model.setShowAll(false)

        XCTAssertEqual(model.visibleFoods.map(\.name), ["Open"])
        XCTAssertEqual(model.tableRowCount, 2)
    }

    func testSearchingFiltersByNameWithoutControlRow() {
        let model = FoodListScreenModel()
        model.updateFoods([
            FoodLocation(name: "Hero Coffee", isOpen: true, statusText: "Open"),
            FoodLocation(name: "Mercante", isOpen: true, statusText: "Open")
        ])

        model.setSearching(true)
        model.setSearchQuery("hero")

        XCTAssertEqual(model.visibleFoods.map(\.name), ["Hero Coffee"])
        XCTAssertEqual(model.tableRowCount, 1)
        XCTAssertEqual(model.food(atRow: 0)?.name, "Hero Coffee")
    }

    func testLoadingEmptyStateOnlyWhenNotSearchingAndNoFoods() {
        let model = FoodListScreenModel()

        XCTAssertTrue(model.isShowingLoadingEmptyState)

        model.setSearching(true)
        XCTAssertFalse(model.isShowingLoadingEmptyState)
    }
}
