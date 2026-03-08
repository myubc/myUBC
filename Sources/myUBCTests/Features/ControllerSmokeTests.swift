@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class ControllerSmokeTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    func testFoodTableViewControllerLoadsAndSearches() async throws {
        let container = try makeControllerContainer()
        let controller = FoodTableViewController()
        controller.container = container
        controller.loadViewIfNeeded()

        let loaded = expectation(description: "food loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 2)

        XCTAssertGreaterThan(controller.tableView(controller.tableView, numberOfRowsInSection: 0), 1)
        controller.searchController.isActive = true
        controller.searchController.searchBar.text = "hero"
        controller.updateSearchResults(for: controller.searchController)
        XCTAssertEqual(controller.tableView(controller.tableView, numberOfRowsInSection: 0), 1)
    }

    func testFoodDetailControllerLoadsDetailModel() async throws {
        let container = try makeControllerContainer()
        let controller = FoodDetailTableViewController()
        controller.container = container
        controller.target = FoodLocation(name: "Hero Coffee Bar", isOpen: true, statusText: "Open")
        controller.targetDetail = FoodItem(
            spaceTitle: "Hero Coffee Bar",
            url: "https://food.ubc.ca/places/hero-coffee-bar/",
            tvalue: "",
            address: "2015 Main Mall\\nVancouver",
            rating: 4
        )
        controller.loadViewIfNeeded()

        let loaded = expectation(description: "food detail loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 2)

        XCTAssertNotNil(controller.detailItem)
        XCTAssertGreaterThanOrEqual(controller.tableView(controller.tableView, numberOfRowsInSection: 0), 3)
    }

    private func makeControllerContainer() throws -> AppContainer {
        let feedData = try fixtureData("feed_me")
        let detailData = try fixtureData("food_detail")

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        URLProtocolStub.handler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            let abs = url.absoluteString
            if abs.contains("/feedme/") {
                return URLProtocolStub.successResponse(for: url, data: feedData)
            }
            if abs.contains("/places/") {
                return URLProtocolStub.successResponse(for: url, data: detailData)
            }
            return URLProtocolStub.successResponse(for: url, data: Data("<html></html>".utf8))
        }

        let client = NetworkClient(session: URLSession(configuration: config))
        return AppContainer(networkClient: client, cacheStore: CacheStore())
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
