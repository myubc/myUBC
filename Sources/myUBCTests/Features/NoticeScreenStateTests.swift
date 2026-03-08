@testable import myUBC
import XCTest

final class NoticeScreenStateTests: XCTestCase {
    func testSuccessStateBuildsRowsAndTimestampVisibility() {
        var state = NoticeScreenState()

        state.applySuccess(
            notifications: [CampusNotification(title: "Notice", time: "now", content: "content", notificationID: "n1")],
            lastUpdated: Date(),
            banner: nil
        )

        XCTAssertTrue(state.wasLastUpdateSuccessful)
        XCTAssertEqual(state.rowCount, 2)
        XCTAssertTrue(state.showsTimestampLabel)
    }

    func testFailureStateClearsRowsAndUsesBannerMessage() {
        var state = NoticeScreenState()
        let banner = CacheBanner(message: "Offline copy shown", style: .offline)

        state.applyFailure(lastUpdated: nil, banner: banner)

        XCTAssertFalse(state.wasLastUpdateSuccessful)
        XCTAssertEqual(state.rowCount, 1)
        XCTAssertEqual(state.footerMessage, "Offline copy shown")
        XCTAssertFalse(state.showsTimestampLabel)
    }
}
