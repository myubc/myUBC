@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class ExtensionsUtilityTests: XCTestCase {
    func testSafeSubscriptAndDuplicateFilter() {
        let values = [1, 2, 3]
        XCTAssertEqual(values[safe: 1], 2)
        XCTAssertNil(values[safe: 10])

        let deduped = ["a", "A", "b", "B", "b"].filterDuplicates { lhs, rhs in
            lhs.lowercased() == rhs.lowercased()
        }
        XCTAssertEqual(deduped, ["a", "b"])
    }

    func testDateComponentHelpers() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        XCTAssertGreaterThanOrEqual(now.interval(ofComponent: .day, fromDate: yesterday), 1)

        let str = now.toString(withFormat: "yyyy-MM-dd")
        XCTAssertEqual(str.count, 10)

        XCTAssertLessThanOrEqual(now.startOfDay, now)
        XCTAssertGreaterThanOrEqual(now.endOfDay, now)
        XCTAssertLessThanOrEqual(now.startOfMonth, now)
        XCTAssertGreaterThanOrEqual(now.endOfMonth, now)
        XCTAssertNotNil(now.localDate())

        let components = now.get(.year, .month, .day)
        XCTAssertNotNil(components.year)
        XCTAssertGreaterThan(now.get(.month), 0)
    }

    func testHTTPResponseHelper() throws {
        let ok = try XCTUnwrap(HTTPURLResponse(url: XCTUnwrap(URL(string: "https://example.com")), statusCode: 200, httpVersion: nil, headerFields: nil))
        let notFound = try XCTUnwrap(HTTPURLResponse(url: XCTUnwrap(URL(string: "https://example.com")), statusCode: 404, httpVersion: nil, headerFields: nil))
        XCTAssertTrue(ok.isResponseOK())
        XCTAssertFalse(notFound.isResponseOK())
    }

    func testSpinnerAttachAndRemove() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let spinner = UIViewController.displaySpinner(onView: host, effect: UIBlurEffect(style: .systemChromeMaterial))
        let exp = expectation(description: "spinner attached")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertTrue(host.subviews.contains(spinner))
            UIViewController.removeSpinner(spinner: spinner)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testBarButtonFactory() {
        let button = UIBarButtonItem.appNavIcon(systemName: "xmark", target: nil, action: #selector(getter: UIView.frame), accessibilityLabel: "Close")
        XCTAssertEqual(button.tintColor, .label)
        XCTAssertEqual(button.accessibilityLabel, "Close")
    }

    func testUITableViewReloadWorkaroundAndImageURLNoop() {
        let imageView = UIImageView()
        imageView.url(nil)
        XCTAssertNil(imageView.image)
    }

    func testUIImageGifHelpersOnInvalidData() {
        XCTAssertNil(UIImage.gifImageWithData(Data()))
        XCTAssertNil(UIImage.gifImageWithName("does-not-exist"))
        XCTAssertEqual(UIImage.gcdForPair(nil, nil), 0)
        XCTAssertEqual(UIImage.gcdForPair(6, nil), 6)
        XCTAssertEqual(UIImage.gcdForPair(8, 12), 4)
        XCTAssertEqual(UIImage.gcdForArray([]), 1)
        XCTAssertEqual(UIImage.gcdForArray([6, 12, 18]), 6)
    }

    func testAttributedStringIconBuilders() {
        let full = NSMutableAttributedString.setIconWithTitleString(isSuccess: true, isCaution: false, text: "Available")
        XCTAssertTrue(full.string.contains("Available"))

        let small = NSMutableAttributedString.setIconWithSmallLabelString(isSuccess: false, isCaution: true, text: "Limited")
        XCTAssertTrue(small.string.contains("Limited"))

        let customIcon = NSMutableAttributedString(string: "P")
        let custom = NSMutableAttributedString.setCustomIconWithTitleString(icon: customIcon, text: "Parking")
        XCTAssertTrue(custom.string.contains("Parking"))
    }
}
