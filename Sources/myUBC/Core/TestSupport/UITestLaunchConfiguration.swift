//
//  UITestLaunchConfiguration.swift
//  myUBC
//
//  Created by OpenAI myUBC on 2026-03-07.
//

import Foundation
import UIKit

@MainActor
enum UITestLaunchScenario: String {
    case landingBaseline = "landing_baseline"
    case landingNotice = "landing_notice"
    case landingUpassOnly = "landing_upass_only"
    case landingTimerOnly = "landing_timer_only"
}

@MainActor
enum UITestLaunchConfiguration {
    private static let launchArgument = "UI_TESTING"
    private static let scenarioEnvironmentKey = "UI_TEST_SCENARIO"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static var scenario: UITestLaunchScenario? {
        guard isEnabled else { return nil }
        guard let rawValue = ProcessInfo.processInfo.environment[scenarioEnvironmentKey] else {
            return .landingBaseline
        }
        return UITestLaunchScenario(rawValue: rawValue)
    }

    static func makeAppContainer() -> AppContainer {
        guard let scenario else {
            return AppContainer()
        }

        prepareRuntime(for: scenario)

        return AppContainer(
            pendingRouteStore: PendingAppRouteStore(),
            foodService: StubFoodService(scenario: scenario),
            foodDetailService: StubFoodDetailService(),
            parkingService: StubParkingService(),
            infoService: StubInfoService(),
            calendarService: StubCalendarService(),
            libraryService: StubLibraryService(),
            sanityCheckService: StubSanityCheckService(scenario: scenario)
        )
    }

    static func prepareRuntime() {
        prepareRuntime(for: scenario)
    }

    static func prepareRuntime(for scenario: UITestLaunchScenario?) {
        guard isEnabled, let scenario else { return }
        UIView.setAnimationsEnabled(false)

        UserDefaults.standard.set(AppVersionCoordinator.currentVersion, forKey: AppVersionCoordinator.whatsNewVersionKey)
        ReminderStateStore.clearUpassReminder()
        ReminderStateStore.clearChargerTimer()

        switch scenario {
        case .landingBaseline:
            break
        case .landingNotice:
            ReminderStateStore.setUpassReminder(DateComponents(timeZone: .current, day: 16, hour: 9, minute: 0))
            ReminderStateStore.setChargerTimer(targetDate: Date().addingTimeInterval(30 * 60))
        case .landingUpassOnly:
            ReminderStateStore.setUpassReminder(DateComponents(timeZone: .current, day: 16, hour: 9, minute: 0))
        case .landingTimerOnly:
            ReminderStateStore.setChargerTimer(targetDate: Date().addingTimeInterval(30 * 60))
        }
    }
}

private enum UITestFixtures {
    static func cached<T>(_ value: T, lastUpdated: Date = Date()) -> CachedValue<T> {
        CachedValue(
            value: value,
            isStale: false,
            isFromCache: true,
            hadNetworkError: false,
            lastUpdated: lastUpdated,
            networkError: nil
        )
    }

    static let foodLocations: [FoodLocation] = [
        FoodLocation(
            name: "Starbucks @ UBC",
            isOpen: true,
            statusText: "Open",
            slug: "starbucks",
            url: "https://example.com/starbucks",
            address: "6138 Student Union Blvd",
            rating: 4
        ),
        FoodLocation(
            name: "Tim Hortons",
            isOpen: false,
            statusText: "Closed",
            slug: "tim-hortons",
            url: "https://example.com/tim",
            address: "2335 Lower Mall",
            rating: 3
        ),
        FoodLocation(
            name: "Booster Juice Life",
            isOpen: true,
            statusText: "Open",
            slug: "booster-juice",
            url: "https://example.com/booster",
            address: "Life Building",
            rating: 4
        ),
        FoodLocation(
            name: "Triple Os",
            isOpen: false,
            statusText: "Closed",
            slug: "triple-os",
            url: "https://example.com/tripleos",
            address: "University Boulevard",
            rating: 3
        )
    ]

    static let parkingLots = [
        ParkingAnnotation(lotName: .north, status: [.good])
    ]

    static let notifications = [
        CampusNotification(title: "Transit notice", time: "now", content: "Mock campus notification", notificationID: "ui-test-notice")
    ]

    static func libraryModel() -> LibraryModel {
        let model = LibraryModel()
        model.iphones2 = [
            Equipment(type: .IPhone2, name: "iPhone charger", location: "IKB", total: "2", details: [
                EquipmentStatus(isAvailable: true, referenceNo: "IP-1", date: nil, note: "")
            ])
        ]
        model.macs1 = [
            Equipment(type: .Mac1, name: "Mac charger", location: "IKB", total: "1", details: [
                EquipmentStatus(isAvailable: true, referenceNo: "MAC-1", date: nil, note: "")
            ])
        ]
        model.andriods2 = [
            Equipment(type: .Andriod2, name: "Android charger", location: "IKB", total: "1", details: [
                EquipmentStatus(isAvailable: true, referenceNo: "AND-1", date: nil, note: "")
            ])
        ]
        return model
    }

    static func calendarEvents(now: Date = Date()) -> [CampusCalendarEvent] {
        [
            CampusCalendarEvent(
                date: now,
                events: [CampusEventDetail(isImportant: true, eventDescription: "Mock event")]
            )
        ]
    }
}

private struct StubFoodService: FoodServicing {
    let scenario: UITestLaunchScenario

    func fetchLocations(forceRefresh _: Bool) async -> Result<CachedValue<[FoodLocation]>, AppError> {
        .success(UITestFixtures.cached(UITestFixtures.foodLocations))
    }
}

private struct StubFoodDetailService: FoodDetailServicing {
    func fetchDetails(url _: String, forceRefresh _: Bool) async -> Result<CachedValue<FoodDetailItem>, AppError> {
        .failure(.unknown)
    }
}

private struct StubParkingService: ParkingServicing {
    func fetchParking(forceRefresh _: Bool) async -> Result<CachedValue<[ParkingAnnotation]>, AppError> {
        .success(UITestFixtures.cached(UITestFixtures.parkingLots))
    }
}

private struct StubInfoService: InfoServicing {
    func fetchNotifications(forceRefresh _: Bool) async -> Result<CachedValue<[CampusNotification]>, AppError> {
        .success(UITestFixtures.cached(UITestFixtures.notifications))
    }
}

private struct StubCalendarService: CalendarServicing {
    func fetchMonth(_: Date, forceRefresh _: Bool) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
        .success(UITestFixtures.cached(UITestFixtures.calendarEvents()))
    }
}

private struct StubLibraryService: LibraryServicing {
    func fetchLibrary(forceRefresh _: Bool) async -> Result<CachedValue<LibraryModel>, AppError> {
        .success(UITestFixtures.cached(UITestFixtures.libraryModel()))
    }
}

private struct StubSanityCheckService: SanityCheckServicing {
    let scenario: UITestLaunchScenario

    func fetch() async -> Result<SanityCheckResult, AppError> {
        switch scenario {
        case .landingBaseline:
            return .success(SanityCheckResult(isStaging: false, isNewVersionAvailable: false, notice: nil))
        case .landingNotice:
            return .success(
                SanityCheckResult(
                    isStaging: false,
                    isNewVersionAvailable: false,
                    notice: SanityNotice(
                        title: "Ongoing Issue",
                        detail: "Calendar incident is being investigated.",
                        link: nil,
                        skipVersions: []
                    )
                )
            )
        case .landingUpassOnly, .landingTimerOnly:
            return .success(SanityCheckResult(isStaging: false, isNewVersionAvailable: false, notice: nil))
        }
    }
}
