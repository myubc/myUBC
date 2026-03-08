@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class AppDelegateDeepLinkTests: XCTestCase {
    func testDeepLinkResetDetectionWithEventInAnyPosition() throws {
        let first = try XCTUnwrap(URL(string: "myubc://main?event=new-layout&source=appstore"))
        let second = try XCTUnwrap(URL(string: "myubc://main?source=appstore&event=new-layout"))
        XCTAssertTrue(AppDelegate.shouldResetWhatsNewVersion(for: first))
        XCTAssertTrue(AppDelegate.shouldResetWhatsNewVersion(for: second))
    }

    func testApplicationOpenOnlyResetsWhenEventIsPresent() throws {
        let defaults = UserDefaults.standard
        let key = "whats_new_version"
        let original = defaults.object(forKey: key)
        defaults.set("1.0", forKey: key)

        let appDelegate = AppDelegate()
        let eventURL = try XCTUnwrap(URL(string: "myubc://main?source=appstore&event=new-layout"))
        _ = appDelegate.application(UIApplication.shared, open: eventURL, options: [:])
        XCTAssertEqual(defaults.string(forKey: key), "n/a")

        defaults.set("2.0", forKey: key)
        let nonEventURL = try XCTUnwrap(URL(string: "myubc://main?source=appstore"))
        _ = appDelegate.application(UIApplication.shared, open: nonEventURL, options: [:])
        XCTAssertEqual(defaults.string(forKey: key), "2.0")

        if let original {
            defaults.set(original, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
