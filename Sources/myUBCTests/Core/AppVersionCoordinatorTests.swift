@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class AppVersionCoordinatorTests: XCTestCase {
    func testShouldPresentWhatsNewUsesVersionComparison() {
        XCTAssertTrue(AppVersionCoordinator.shouldPresentWhatsNew(currentVersion: "1.0", lastSeenVersion: nil))
        XCTAssertTrue(AppVersionCoordinator.shouldPresentWhatsNew(currentVersion: "1.1", lastSeenVersion: "1.0"))
        XCTAssertFalse(AppVersionCoordinator.shouldPresentWhatsNew(currentVersion: "1.1", lastSeenVersion: "1.1"))
        XCTAssertFalse(AppVersionCoordinator.shouldPresentWhatsNew(currentVersion: nil, lastSeenVersion: "1.0"))
        XCTAssertFalse(AppVersionCoordinator.shouldPresentWhatsNew(currentVersion: "", lastSeenVersion: "1.0"))
    }

    func testSanityNoticeSkipFiltering() {
        let notice = SanityNotice(title: "Ongoing Issue", detail: "Calendar issue", link: nil, skipVersions: ["2.2.1"])
        XCTAssertFalse(notice.shouldShow(for: "2.2.1"))
        XCTAssertTrue(notice.shouldShow(for: "2.2.2"))
        XCTAssertTrue(notice.shouldShow(for: nil))
    }
}
