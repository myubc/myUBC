@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class AppDelegateRegressionTests: XCTestCase {
    func testDidFinishLaunchingIncrementsLaunchCountByOne() {
        let defaults = UserDefaults.standard
        let key = Constants.userdefault_launchCount
        let original = defaults.object(forKey: key)
        defaults.set(0, forKey: key)

        let appDelegate = AppDelegate()
        _ = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        XCTAssertEqual(defaults.integer(forKey: key), 1)

        if let original {
            defaults.set(original, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func testLibraryURLsUseHTTPS() {
        let urls = [
            Constants.libraryURL_iphone1,
            Constants.libraryURL_iphone2,
            Constants.libraryURL_android1,
            Constants.libraryURL_android2,
            Constants.libraryURL_mac1,
            Constants.libraryURL_mac2
        ]
        XCTAssertTrue(urls.allSatisfy { $0.hasPrefix("https://") })
    }
}
