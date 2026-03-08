@testable import myUBC
import UIKit
import XCTest

@MainActor
final class ParkingViewControllerTests: XCTestCase, ViewFixtureLoading {
    func testShowLoadingUsesInlineIndicatorInsteadOfAlertPresentation() {
        let controller = ParkingViewController()
        controller.view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))

        controller.showLoading()

        let indicator = firstSubview(of: UIActivityIndicatorView.self, in: controller.view)
        XCTAssertEqual(indicator?.accessibilityIdentifier, "parking.loading")
        XCTAssertTrue(indicator?.isAnimating ?? false)
        XCTAssertFalse(controller.view.isUserInteractionEnabled)

        controller.dismissLoading()

        XCTAssertFalse(indicator?.isAnimating ?? true)
        XCTAssertTrue(controller.view.isUserInteractionEnabled)
    }
}
