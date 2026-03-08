//
//  DataHub.swift
//  myUBC
//
//  Created by myUBC on 2023-01-06.
//

import Foundation

actor DataHub {
    private let food: FoodServicing
    private let parking: ParkingServicing
    private let info: InfoServicing
    private let library: LibraryServicing
    private let calendar: CalendarServicing

    init(food: FoodServicing, parking: ParkingServicing, info: InfoServicing, library: LibraryServicing, calendar: CalendarServicing) {
        self.food = food
        self.parking = parking
        self.info = info
        self.library = library
        self.calendar = calendar
    }

    typealias FoodResult = Result<CachedValue<[FoodLocation]>, AppError>
    typealias ParkingResult = Result<CachedValue<[ParkingAnnotation]>, AppError>
    typealias InfoResult = Result<CachedValue<[CampusNotification]>, AppError>
    typealias LibraryResult = Result<CachedValue<LibraryModel>, AppError>
    typealias CalendarResult = Result<CachedValue<[CampusCalendarEvent]>, AppError>

    struct LandingSnapshot {
        let food: FoodResult
        let parking: ParkingResult
        let info: InfoResult
        let library: LibraryResult
        let calendar: CalendarResult
    }

    private var inFlightSnapshotTask: Task<LandingSnapshot, Never>?

    struct StatusSummary {
        let food: Bool
        let parking: Bool
        let info: Bool
        let library: Bool
        let calendar: Bool
    }

    func loadLandingSnapshot() async -> LandingSnapshot {
        if let inFlightSnapshotTask {
            return await inFlightSnapshotTask.value
        }

        let task = Task { [food, parking, info, library, calendar] in
            async let foodStatus = food.fetchLocations()
            async let parkingStatus = parking.fetchParking()
            async let infoStatus = info.fetchNotifications()
            async let libraryStatus = library.fetchLibrary()
            async let calendarStatus = calendar.fetchMonth(Date())
            return await LandingSnapshot(
                food: foodStatus,
                parking: parkingStatus,
                info: infoStatus,
                library: libraryStatus,
                calendar: calendarStatus
            )
        }

        inFlightSnapshotTask = task
        let snapshot = await task.value
        inFlightSnapshotTask = nil
        return snapshot
    }

    func refreshAll() async -> StatusSummary {
        let snapshot = await loadLandingSnapshot()

        let foodOk = (try? snapshot.food.get()) != nil
        let parkingOk = (try? snapshot.parking.get()) != nil
        let infoOk = (try? snapshot.info.get()) != nil
        let libraryOk = (try? snapshot.library.get()) != nil
        let calendarOk = (try? snapshot.calendar.get()) != nil

        return StatusSummary(food: foodOk, parking: parkingOk, info: infoOk, library: libraryOk, calendar: calendarOk)
    }
}
