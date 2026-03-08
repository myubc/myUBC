//
//  LandingViewModel.swift
//  myUBC
//
//  Created by myUBC on 2025-07-07.
//

import Foundation

@MainActor
final class LandingViewModel {
    private let dataHub: DataHub

    private(set) var foodLocations: [FoodLocation] = []
    private(set) var libraryModel = LibraryModel()
    private(set) var libraryLastUpdated: Date?
    private(set) var calendarEvents: [CampusCalendarEvent] = []
    private(set) var parkingData: [ParkingAnnotation] = []
    private(set) var notifications: [CampusNotification] = []
    private var sectionStatus: [LandingPageSectionType: Bool] = [:]

    init(dataHub: DataHub) {
        self.dataHub = dataHub
        sectionStatus[.upass] = true
    }

    func loadSnapshot() async {
        let snapshot = await dataHub.loadLandingSnapshot()
        apply(snapshot)
    }

    func isSectionLoading(_ type: LandingPageSectionType) -> Bool {
        sectionStatus[type] == nil
    }

    func isSectionAvailable(_ type: LandingPageSectionType) -> Bool {
        sectionStatus[type] ?? false
    }

    private func apply(_ snapshot: DataHub.LandingSnapshot) {
        switch snapshot.food {
        case let .success(cached):
            foodLocations = cached.value
            sectionStatus[.food] = true
        case .failure:
            foodLocations = []
            sectionStatus[.food] = false
        }

        switch snapshot.library {
        case let .success(cached):
            libraryModel = cached.value
            libraryLastUpdated = cached.lastUpdated
            sectionStatus[.charger] = true
        case .failure:
            libraryModel = LibraryModel()
            libraryLastUpdated = nil
            sectionStatus[.charger] = false
        }

        switch snapshot.calendar {
        case let .success(cached):
            calendarEvents = cached.value
            sectionStatus[.calendar] = true
        case .failure:
            calendarEvents = []
            sectionStatus[.calendar] = false
        }

        switch snapshot.info {
        case let .success(cached):
            notifications = cached.value
            sectionStatus[.info] = true
        case .failure:
            notifications = []
            sectionStatus[.info] = false
        }

        switch snapshot.parking {
        case let .success(cached):
            parkingData = cached.value
            sectionStatus[.parking] = true
        case .failure:
            parkingData = []
            sectionStatus[.parking] = false
        }
    }
}
