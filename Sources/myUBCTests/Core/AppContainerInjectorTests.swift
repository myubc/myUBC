@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class AppContainerInjectorTests: XCTestCase {
    func testInjectorPropagatesIntoNavigationAndTabHierarchy() {
        let container = AppContainer()

        let root = UIViewController()
        let navChild = InjectableProbeController()
        let nav = UINavigationController(rootViewController: navChild)
        let tabChild = InjectableProbeController()
        let tab = UITabBarController()
        tab.viewControllers = [tabChild]

        root.addChild(nav)
        nav.didMove(toParent: root)
        root.addChild(tab)
        tab.didMove(toParent: root)

        AppContainerInjector.inject(container, into: root)

        XCTAssertTrue(navChild.container === container)
        XCTAssertTrue(tabChild.container === container)
    }
}
