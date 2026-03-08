@testable import myUBC
import XCTest

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadMetadataPopulatesNotificationsAndSanityFlag() async {
        let viewModel = HomeViewModel(
            infoService: HomeInfoService(result: .success(CachedValue(
                value: [CampusNotification(title: "COVID Update", time: "now", content: "COVID advisory", notificationID: "n1")],
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            ))),
            sanityCheckService: HomeSanityService(result: .success(
                SanityCheckResult(isStaging: false, isNewVersionAvailable: false, notice: nil)
            ))
        )

        await viewModel.loadMetadata()

        XCTAssertEqual(viewModel.notifications.first?.notificationID, "n1")
        XCTAssertFalse(viewModel.sanityCheckOn)
    }

    func testDestinationRoutesBulletinWhenSanityAllows() async throws {
        let viewModel = HomeViewModel(
            infoService: HomeInfoService(result: .success(CachedValue(
                value: [CampusNotification(title: "COVID Update", time: "now", content: "COVID advisory", notificationID: "covid-id")],
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            ))),
            sanityCheckService: HomeSanityService(result: .success(
                SanityCheckResult(isStaging: true, isNewVersionAvailable: false, notice: nil)
            ))
        )
        await viewModel.loadMetadata()

        let bulletinIndex = try XCTUnwrap(HomeItem.local.firstIndex { $0.segue == "showBulletin" })
        XCTAssertEqual(viewModel.destination(for: bulletinIndex), .bulletin("covid-id"))
    }

    func testBadgeNumberMapsPendingReminderCount() {
        let viewModel = HomeViewModel(
            infoService: HomeInfoService(result: .failure(.offline)),
            sanityCheckService: HomeSanityService(result: .failure(.offline))
        )

        XCTAssertEqual(viewModel.badgeNumber(pendingReminderCount: 2), 2)
        XCTAssertEqual(viewModel.badgeNumber(pendingReminderCount: 0), -1)
    }

    func testShouldRouteBulletinToWebViewGuardrails() {
        let covid = CampusNotification(title: "COVID Update", time: "now", content: "COVID guidance", notificationID: "n1")
        let nonCovid = CampusNotification(title: "Campus Notice", time: "now", content: "General update", notificationID: "n2")

        XCTAssertTrue(HomeViewModel.shouldRouteBulletinToWebView(notification: covid, sanityCheckOn: true))
        XCTAssertFalse(HomeViewModel.shouldRouteBulletinToWebView(notification: covid, sanityCheckOn: false))
        XCTAssertFalse(HomeViewModel.shouldRouteBulletinToWebView(notification: nonCovid, sanityCheckOn: true))
        XCTAssertFalse(HomeViewModel.shouldRouteBulletinToWebView(notification: nil, sanityCheckOn: true))
    }
}

private actor HomeInfoService: InfoServicing {
    let result: Result<CachedValue<[CampusNotification]>, AppError>

    init(result: Result<CachedValue<[CampusNotification]>, AppError>) {
        self.result = result
    }

    func fetchNotifications(forceRefresh _: Bool) async -> Result<CachedValue<[CampusNotification]>, AppError> {
        result
    }
}

private actor HomeSanityService: SanityCheckServicing {
    let result: Result<SanityCheckResult, AppError>

    init(result: Result<SanityCheckResult, AppError>) {
        self.result = result
    }

    func fetch() async -> Result<SanityCheckResult, AppError> {
        result
    }
}
