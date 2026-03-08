@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class WebViewNavigationPolicyTests: XCTestCase {
    func testPolicyAllowsOnlyUBCHostByDefault() throws {
        let controller = WebViewController()
        controller.configuration = .ubc(url: "https://www.ubc.ca")

        let ubcURL = try XCTUnwrap(URL(string: "https://www.ubc.ca/students"))
        let externalURL = try XCTUnwrap(URL(string: "https://example.com"))
        let ubcPolicy = controller.policy(for: ubcURL)
        let externalPolicy = controller.policy(for: externalURL)
        let nilPolicy = controller.policy(for: nil)

        XCTAssertEqual(ubcPolicy.rawValue, WKNavigationActionPolicy.allow.rawValue)
        XCTAssertEqual(externalPolicy.rawValue, WKNavigationActionPolicy.cancel.rawValue)
        XCTAssertEqual(nilPolicy.rawValue, WKNavigationActionPolicy.cancel.rawValue)
    }

    func testPolicyAllowsAnyHostWhenRestrictionDisabled() throws {
        let controller = WebViewController()
        controller.configuration = .unrestricted(url: "https://www.ubc.ca", address: "Secure Connection")

        let externalURL = try XCTUnwrap(URL(string: "https://example.com"))
        let policy = controller.policy(for: externalURL)
        let nilPolicy = controller.policy(for: nil)
        XCTAssertEqual(policy.rawValue, WKNavigationActionPolicy.allow.rawValue)
        XCTAssertEqual(nilPolicy.rawValue, WKNavigationActionPolicy.allow.rawValue)
    }

    func testReadOnlyPolicyStillBlocksExternalHosts() throws {
        let controller = WebViewController()
        controller.configuration = .ubcReadOnly(url: "https://www.ubc.ca")

        let ubcURL = try XCTUnwrap(URL(string: "https://students.ubc.ca"))
        let externalURL = try XCTUnwrap(URL(string: "https://example.com"))

        XCTAssertEqual(controller.policy(for: ubcURL), .allow)
        XCTAssertEqual(controller.policy(for: externalURL), .cancel)
        XCTAssertTrue(controller.configuration.navigationPolicy.blocksPageInteractions)
    }
}
