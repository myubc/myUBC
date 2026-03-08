@testable import myUBC
import Foundation

enum TestDoubles {
    actor CountingFoodService: FoodServicing {
        private(set) var count = 0

        func fetchLocations(forceRefresh _: Bool) async -> Result<CachedValue<[FoodLocation]>, AppError> {
            count += 1
            try? await Task.sleep(nanoseconds: 100_000_000)
            let value = CachedValue(
                value: [FoodLocation(name: "Food", isOpen: true, statusText: "Open")],
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            )
            return .success(value)
        }
    }

    actor CountingParkingService: ParkingServicing {
        private(set) var count = 0

        func fetchParking(forceRefresh _: Bool) async -> Result<CachedValue<[ParkingAnnotation]>, AppError> {
            count += 1
            try? await Task.sleep(nanoseconds: 100_000_000)
            let value = CachedValue(
                value: [ParkingAnnotation(lotName: .north, status: [.good, .full])],
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            )
            return .success(value)
        }
    }

    actor CountingInfoService: InfoServicing {
        private(set) var count = 0

        func fetchNotifications(forceRefresh _: Bool) async -> Result<CachedValue<[CampusNotification]>, AppError> {
            count += 1
            try? await Task.sleep(nanoseconds: 100_000_000)
            let value = CachedValue(
                value: [CampusNotification(title: "t", time: "now", content: "c", notificationID: "n")],
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            )
            return .success(value)
        }
    }

    actor CountingLibraryService: LibraryServicing {
        private(set) var count = 0

        func fetchLibrary(forceRefresh _: Bool) async -> Result<CachedValue<LibraryModel>, AppError> {
            count += 1
            try? await Task.sleep(nanoseconds: 100_000_000)
            let model = LibraryModel()
            model.iphones1 = [Equipment(type: .IPhone1, name: "iPhone", location: "IKB", total: "1", details: [])]
            let value = CachedValue(
                value: model,
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            )
            return .success(value)
        }
    }

    actor CountingCalendarService: CalendarServicing {
        private(set) var count = 0

        func fetchMonth(_: Date, forceRefresh _: Bool) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
            count += 1
            try? await Task.sleep(nanoseconds: 100_000_000)
            let value = CachedValue(
                value: [CampusCalendarEvent(date: Date(), events: [CampusEventDetail(isImportant: false, eventDescription: "E")])],
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            )
            return .success(value)
        }
    }

    actor FailingCalendarService: CalendarServicing {
        func fetchMonth(_: Date, forceRefresh _: Bool) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
            .failure(.offline)
        }
    }

    actor StubSanityCheckService: SanityCheckServicing {
        let result: Result<SanityCheckResult, AppError>

        init(result: Result<SanityCheckResult, AppError>) {
            self.result = result
        }

        func fetch() async -> Result<SanityCheckResult, AppError> {
            result
        }
    }

    struct MockFoodService: FoodServicing {
        let result: Result<CachedValue<[FoodLocation]>, AppError>

        func fetchLocations(forceRefresh _: Bool) async -> Result<CachedValue<[FoodLocation]>, AppError> {
            result
        }
    }

    struct MockFoodDetailService: FoodDetailServicing {
        let result: Result<CachedValue<FoodDetailItem>, AppError>

        func fetchDetails(url _: String, forceRefresh _: Bool) async -> Result<CachedValue<FoodDetailItem>, AppError> {
            result
        }
    }

    struct MockCalendarService: CalendarServicing {
        let result: Result<CachedValue<[CampusCalendarEvent]>, AppError>

        func fetchMonth(_: Date, forceRefresh _: Bool) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
            result
        }
    }

    struct MockInfoService: InfoServicing {
        let result: Result<CachedValue<[CampusNotification]>, AppError>

        func fetchNotifications(forceRefresh _: Bool) async -> Result<CachedValue<[CampusNotification]>, AppError> {
            result
        }
    }

    struct MockParkingService: ParkingServicing {
        let result: Result<CachedValue<[ParkingAnnotation]>, AppError>

        func fetchParking(forceRefresh _: Bool) async -> Result<CachedValue<[ParkingAnnotation]>, AppError> {
            result
        }
    }

    struct MockLibraryService: LibraryServicing {
        let result: Result<CachedValue<LibraryModel>, AppError>

        func fetchLibrary(forceRefresh _: Bool) async -> Result<CachedValue<LibraryModel>, AppError> {
            result
        }
    }
}
