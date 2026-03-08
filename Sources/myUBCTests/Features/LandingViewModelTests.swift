@testable import myUBC
import XCTest

@MainActor
final class LandingViewModelTests: XCTestCase {
    func testLoadSnapshotMapsSuccessfulSections() async {
        let viewModel = LandingViewModel(dataHub: DataHub(
            food: LandingFoodService(),
            parking: LandingParkingService(),
            info: LandingInfoService(),
            library: LandingLibraryService(),
            calendar: LandingCalendarService()
        ))

        await viewModel.loadSnapshot()

        XCTAssertEqual(viewModel.foodLocations.first?.name, "Mercante")
        XCTAssertFalse(viewModel.libraryModel.iphones2.isEmpty)
        XCTAssertEqual(viewModel.notifications.first?.notificationID, "bulletin")
        XCTAssertEqual(viewModel.parkingData.first?.lotName, .north)
        XCTAssertFalse(viewModel.isSectionLoading(.food))
        XCTAssertTrue(viewModel.isSectionAvailable(.charger))
    }

    func testLoadSnapshotClearsDataForFailedSections() async {
        let viewModel = LandingViewModel(dataHub: DataHub(
            food: FailingLandingFoodService(),
            parking: FailingLandingParkingService(),
            info: FailingLandingInfoService(),
            library: FailingLandingLibraryService(),
            calendar: FailingLandingCalendarService()
        ))

        await viewModel.loadSnapshot()

        XCTAssertTrue(viewModel.foodLocations.isEmpty)
        XCTAssertTrue(viewModel.libraryModel.iphones2.isEmpty)
        XCTAssertTrue(viewModel.notifications.isEmpty)
        XCTAssertTrue(viewModel.parkingData.isEmpty)
        XCTAssertFalse(viewModel.isSectionAvailable(.food))
        XCTAssertFalse(viewModel.isSectionAvailable(.parking))
    }
}

private actor LandingFoodService: FoodServicing {
    func fetchLocations(forceRefresh _: Bool) async -> Result<CachedValue<[FoodLocation]>, AppError> {
        .success(CachedValue(
            value: [FoodLocation(name: "Mercante", isOpen: true, statusText: "Open")],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        ))
    }
}

private actor LandingParkingService: ParkingServicing {
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

private actor LandingInfoService: InfoServicing {
    func fetchNotifications(forceRefresh _: Bool) async -> Result<CachedValue<[CampusNotification]>, AppError> {
        .success(CachedValue(
            value: [CampusNotification(title: "Bulletin", time: "Now", content: "Open", notificationID: "bulletin")],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        ))
    }
}

private actor LandingLibraryService: LibraryServicing {
    func fetchLibrary(forceRefresh _: Bool) async -> Result<CachedValue<LibraryModel>, AppError> {
        let model = LibraryModel()
        model.iphones2 = [Equipment(type: .IPhone2, name: "iPhone 15", location: "IKB", total: "1", details: [])]
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

private actor LandingCalendarService: CalendarServicing {
    func fetchMonth(_: Date, forceRefresh _: Bool) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
        .success(CachedValue(
            value: [CampusCalendarEvent(date: Date(), events: [CampusEventDetail(isImportant: true, eventDescription: "Midterm")])],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        ))
    }
}

private actor FailingLandingFoodService: FoodServicing {
    func fetchLocations(forceRefresh _: Bool) async -> Result<CachedValue<[FoodLocation]>, AppError> {
        .failure(.offline)
    }
}

private actor FailingLandingParkingService: ParkingServicing {
    func fetchParking(forceRefresh _: Bool) async -> Result<CachedValue<[ParkingAnnotation]>, AppError> {
        .failure(.offline)
    }
}

private actor FailingLandingInfoService: InfoServicing {
    func fetchNotifications(forceRefresh _: Bool) async -> Result<CachedValue<[CampusNotification]>, AppError> {
        .failure(.offline)
    }
}

private actor FailingLandingLibraryService: LibraryServicing {
    func fetchLibrary(forceRefresh _: Bool) async -> Result<CachedValue<LibraryModel>, AppError> {
        .failure(.offline)
    }
}

private actor FailingLandingCalendarService: CalendarServicing {
    func fetchMonth(_: Date, forceRefresh _: Bool) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
        .failure(.offline)
    }
}
