@testable import myUBC
import XCTest

final class AppShellArchitectureTests: XCTestCase {
    override func tearDown() {
        ReminderStateStore.clearUpassReminder()
        ReminderStateStore.clearChargerTimer()
        super.tearDown()
    }

    func testPendingRouteStoreConsumesOnlyOnce() async {
        let store = PendingAppRouteStore()
        await store.set(.reminders)

        let first = await store.consume()
        let second = await store.consume()

        XCTAssertEqual(first, .reminders)
        XCTAssertNil(second)
    }

    func testSplashLaunchCoordinatorWaitsForMinimumDelayAndReturnsSuccess() async {
        let hub = DataHub(
            food: StaticFoodService(),
            parking: StaticParkingService(),
            info: StaticInfoService(),
            library: StaticLibraryService(),
            calendar: StaticCalendarService()
        )

        let start = Date()
        let result = await SplashLaunchCoordinator.prepareLaunch(using: hub, minimumDelay: 0.05, timeout: 1)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertFalse(result.didTimeout)
        XCTAssertNotNil(result.statusSummary)
        XCTAssertGreaterThanOrEqual(elapsed, 0.045)
    }

    func testSplashLaunchCoordinatorReturnsTimeoutWhenHubDoesNotFinish() async {
        let hub = DataHub(
            food: HangingFoodService(),
            parking: StaticParkingService(),
            info: StaticInfoService(),
            library: StaticLibraryService(),
            calendar: StaticCalendarService()
        )

        let result = await SplashLaunchCoordinator.prepareLaunch(using: hub, minimumDelay: 0, timeout: 0.02)

        XCTAssertTrue(result.didTimeout)
        XCTAssertNil(result.statusSummary)
    }

    func testReminderStateStorePersistsUpassReminderComponents() {
        let components = DateComponents(timeZone: .current, day: 16, hour: 9, minute: 0)

        ReminderStateStore.setUpassReminder(components)

        XCTAssertTrue(ReminderStateStore.hasPendingUpassReminder())
        XCTAssertEqual(ReminderStateStore.upassReminderComponents()?.day, 16)
        XCTAssertEqual(ReminderStateStore.upassReminderComponents()?.hour, 9)
    }

    func testReminderStateStoreClearUpassReminderRemovesState() {
        ReminderStateStore.setUpassReminder(DateComponents(timeZone: .current, day: 20, hour: 12, minute: 0))

        ReminderStateStore.clearUpassReminder()

        XCTAssertFalse(ReminderStateStore.hasPendingUpassReminder())
        XCTAssertNil(ReminderStateStore.upassReminderComponents())
    }
}

private actor StaticFoodService: FoodServicing {
    func fetchLocations(forceRefresh _: Bool) async -> Result<CachedValue<[FoodLocation]>, AppError> {
        .success(CachedValue(
            value: [FoodLocation(name: "Open Kitchen", isOpen: true, statusText: "Open")],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        ))
    }
}

private actor HangingFoodService: FoodServicing {
    func fetchLocations(forceRefresh _: Bool) async -> Result<CachedValue<[FoodLocation]>, AppError> {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return .failure(.offline)
    }
}

private actor StaticParkingService: ParkingServicing {
    func fetchParking(forceRefresh _: Bool) async -> Result<CachedValue<[ParkingAnnotation]>, AppError> {
        .success(CachedValue(
            value: [ParkingAnnotation(lotName: .north, status: [.good])],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        ))
    }
}

private actor StaticInfoService: InfoServicing {
    func fetchNotifications(forceRefresh _: Bool) async -> Result<CachedValue<[CampusNotification]>, AppError> {
        .success(CachedValue(
            value: [CampusNotification(title: "Notice", time: "Now", content: "Open", notificationID: "n1")],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        ))
    }
}

private actor StaticLibraryService: LibraryServicing {
    func fetchLibrary(forceRefresh _: Bool) async -> Result<CachedValue<LibraryModel>, AppError> {
        let model = LibraryModel()
        model.iphones2 = [Equipment(type: .IPhone2, name: "iPhone", location: "IKB", total: "1", details: [])]
        return .success(CachedValue(
            value: model,
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        ))
    }
}

private actor StaticCalendarService: CalendarServicing {
    func fetchMonth(_: Date, forceRefresh _: Bool) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
        .success(CachedValue(
            value: [CampusCalendarEvent(date: Date(), events: [CampusEventDetail(isImportant: false, eventDescription: "Event")])],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        ))
    }
}
