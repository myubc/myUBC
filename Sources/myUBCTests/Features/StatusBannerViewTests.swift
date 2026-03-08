@testable import myUBC
import XCTest

@MainActor
final class StatusBannerViewTests: XCTestCase, ViewFixtureLoading {
    func testOfflineBannerAppliesExpectedMessageAndStyle() throws {
        let banner = StatusBannerView()
        banner.apply(message: "Calendar incident is being investigated.", style: .offline)

        let label = try XCTUnwrap(firstSubview(of: UILabel.self, in: banner))
        XCTAssertEqual(label.text, "Calendar incident is being investigated.")
        XCTAssertEqual(label.textColor, StatusBannerStyle.offline.textColor)
        XCTAssertEqual(banner.backgroundColor, StatusBannerStyle.offline.backgroundColor)
        XCTAssertEqual(banner.accessibilityLabel, "Calendar incident is being investigated.")
    }

    func testInfoBannerAppliesExpectedTextColor() throws {
        let banner = StatusBannerView()
        banner.apply(message: "Data may be slightly stale.", style: .info)

        let label = try XCTUnwrap(firstSubview(of: UILabel.self, in: banner))
        XCTAssertEqual(label.textColor, StatusBannerStyle.info.textColor)
        XCTAssertEqual(banner.backgroundColor, StatusBannerStyle.info.backgroundColor)
    }
}
