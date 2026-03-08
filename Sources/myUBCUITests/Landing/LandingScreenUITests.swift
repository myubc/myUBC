import XCTest

final class LandingScreenUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLandingNoticeScenarioShowsMockedNoticeAndReminderBadge() {
        let app = XCUIApplication()
        app.launch(for: .landingNotice)

        let collection = app.collectionViews["landing.collection"]
        XCTAssertTrue(collection.waitForExistence(timeout: 5))

        let notice = app.otherElements["landing.header.notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        XCTAssertEqual(
            notice.label,
            "Ongoing Issue: Calendar incident is being investigated."
        )

        let bell = app.buttons["landing.header.bell"]
        XCTAssertTrue(bell.waitForExistence(timeout: 2))
        XCTAssertEqual(bell.value as? String, "2")
        XCTAssertTrue(app.staticTexts["Food"].exists)

        add(landingScreenshotAttachment(app: app, named: "Landing Notice"))
    }

    func testReminderButtonPresentsReminderScreenUsingMockedState() {
        let app = XCUIApplication()
        app.launch(for: .landingNotice)

        let bell = app.buttons["landing.header.bell"]
        XCTAssertTrue(bell.waitForExistence(timeout: 5))
        bell.tap()

        XCTAssertTrue(app.navigationBars["Reminder"].waitForExistence(timeout: 5))
        add(landingScreenshotAttachment(app: app, named: "Reminder Screen"))
    }

    func testReminderScreenShowsBothTimerAndUpassEntries() {
        let app = XCUIApplication()
        app.launch(for: .landingNotice)

        let bell = app.buttons["landing.header.bell"]
        XCTAssertTrue(bell.waitForExistence(timeout: 5))
        bell.tap()

        XCTAssertTrue(app.navigationBars["Reminder"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Timer In Progress"].exists)
        XCTAssertTrue(app.staticTexts["Reminder Active"].exists)
    }

    func testLandingBaselineScenarioHidesNoticeAndReminderBadge() {
        let app = XCUIApplication()
        app.launch(for: .landingBaseline)

        XCTAssertTrue(app.collectionViews["landing.collection"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["landing.header.notice"].exists)

        let bell = app.buttons["landing.header.bell"]
        XCTAssertTrue(bell.waitForExistence(timeout: 2))
        XCTAssertEqual(bell.value as? String, "")

        add(landingScreenshotAttachment(app: app, named: "Landing Baseline"))
    }

    func testLandingUsesMockedFoodAndChargerFixtures() {
        let app = XCUIApplication()
        app.launch(for: .landingNotice)

        let collection = app.collectionViews["landing.collection"]
        XCTAssertTrue(collection.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Food"].exists)
        XCTAssertTrue(app.staticTexts["Charger"].exists)

        XCTAssertTrue(
            scrollToFind("Academic Calendar", in: collection, app: app)
        )
        XCTAssertTrue(
            scrollToFind("Parking", in: collection, app: app)
        )
        add(landingScreenshotAttachment(app: app, named: "Landing Sections"))
    }

    func testLandingUpassOnlyScenarioShowsSingleReminderBadge() {
        let app = XCUIApplication()
        app.launch(for: .landingUpassOnly)

        XCTAssertTrue(app.collectionViews["landing.collection"].waitForExistence(timeout: 5))

        let bell = app.buttons["landing.header.bell"]
        XCTAssertTrue(bell.waitForExistence(timeout: 2))
        XCTAssertEqual(bell.value as? String, "1")
    }

    func testLandingTimerOnlyScenarioShowsSingleReminderBadge() {
        let app = XCUIApplication()
        app.launch(for: .landingTimerOnly)

        XCTAssertTrue(app.collectionViews["landing.collection"].waitForExistence(timeout: 5))

        let bell = app.buttons["landing.header.bell"]
        XCTAssertTrue(bell.waitForExistence(timeout: 2))
        XCTAssertEqual(bell.value as? String, "1")
    }

    @discardableResult
    private func scrollToFind(
        _ text: String,
        in collection: XCUIElement,
        app: XCUIApplication,
        maxSwipes: Int = 4
    )
        -> Bool
    {
        if app.staticTexts[text].exists {
            return true
        }

        for _ in 0 ..< maxSwipes {
            collection.swipeUp()
            if app.staticTexts[text].waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }
}
