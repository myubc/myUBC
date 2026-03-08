@testable import myUBC
import XCTest

@MainActor
final class LandingHeaderViewTests: XCTestCase, ViewFixtureLoading {
    override func tearDown() {
        ReminderStateStore.clearUpassReminder()
        ReminderStateStore.clearChargerTimer()
        super.tearDown()
    }

    func testConfigureStatusMessageHidesNoticeByDefault() throws {
        let header: LandingHeader = try loadViewFromNib(named: LandingHeader.nib)
        header.configureStatusMessage(nil)

        let noticeView = try XCTUnwrap(header.subviews.first { $0.accessibilityIdentifier == "landing.header.notice" })
        XCTAssertTrue(noticeView.isHidden)
    }

    func testConfigureStatusMessageShowsNoticeAndBadge() throws {
        let header: LandingHeader = try loadViewFromNib(named: LandingHeader.nib)
        header.bellBtn.badgeString = "2"
        header.bellBtn.badgeTextColor = .white
        header.bellBtn.accessibilityValue = "2"
        header.configureStatusMessage("Ongoing Issue: Calendar incident is being investigated.", style: .offline)

        let noticeView = try XCTUnwrap(header.subviews.first { $0.accessibilityIdentifier == "landing.header.notice" })
        XCTAssertFalse(noticeView.isHidden)
        XCTAssertEqual(noticeView.accessibilityLabel, "Ongoing Issue: Calendar incident is being investigated.")
        XCTAssertEqual(header.bellBtn.accessibilityValue, "2")
    }
}
