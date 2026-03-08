@testable import myUBC
import XCTest

final class WebRoutingTests: XCTestCase {
    func testWebNavigationPolicyEnforcesUBCHosts() throws {
        let ubcURL = try XCTUnwrap(URL(string: "https://students.ubc.ca"))
        let externalURL = try XCTUnwrap(URL(string: "https://example.com"))

        XCTAssertEqual(WebNavigationPolicy.ubcOnly.navigationPolicy(for: ubcURL), .allow)
        XCTAssertEqual(WebNavigationPolicy.ubcOnly.navigationPolicy(for: externalURL), .cancel)
        XCTAssertEqual(WebNavigationPolicy.unrestricted.navigationPolicy(for: externalURL), .allow)
    }

    func testReadOnlyPolicyBlocksInteractions() {
        XCTAssertTrue(WebNavigationPolicy.ubcReadOnly.blocksPageInteractions)
        XCTAssertFalse(WebNavigationPolicy.ubcOnly.blocksPageInteractions)
    }

    func testUpassConfigurationUsesExplicitUnrestrictedPolicy() {
        let configuration = WebViewConfiguration.upassRenewal()

        XCTAssertEqual(configuration.requestURL, Constants.upassLink)
        XCTAssertEqual(configuration.address, "Secure Connection")
        XCTAssertEqual(configuration.navigationPolicy, .unrestricted)
    }
}
