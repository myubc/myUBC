@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class MIBadgeButtonTests: XCTestCase {
    func testBadgeButtonConfigAndAnchors() {
        let button = MIBadgeButton(frame: CGRect(x: 0, y: 0, width: 120, height: 44))
        button.badgeString = "3"
        button.badgeBackgroundColor = .green
        button.badgeTextColor = .black
        button.cornerRadiusFactor = 2
        button.verticalMargin = 8
        button.horizontalMargin = 12
        button.badgeEdgeInsets = UIEdgeInsets(top: 2, left: 3, bottom: 1, right: 4)
        button.edgeInsetTop = 1
        button.edgeInsetLeft = 2
        button.edgeInsetBottom = 3
        button.edgeInsetRight = 4
        button.anchor = 0
        button.leftOffset = 2
        button.anchor = 1
        button.rightOffset = 2
        button.anchor = 2
        button.buttomOffset = 2
        button.anchor = 3
        button.anchor = 4
        button.badgeAnchor = .TopRight(topOffset: 1, rightOffset: 2)
        button.badgeAnchor = .BottomLeft(bottomOffset: 1, leftOffset: 2)
        button.badgeAnchor = .BottomRight(bottomOffset: 1, rightOffset: 2)
        button.badgeAnchor = .center
        button.badgeString = ""

        let labels = button.subviews.compactMap { $0 as? UILabel }
        XCTAssertFalse(labels.isEmpty)
        XCTAssertTrue(labels.contains(where: { $0.text == "" || $0.text == "3" }))
    }
}
