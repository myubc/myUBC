//
//  HomeViewModel.swift
//  myUBC
//
//  Created by myUBC on 2025-07-07.
//

import Foundation

@MainActor
final class HomeViewModel {
    enum Destination: Equatable {
        case upass
        case food
        case calendar
        case parking
        case bulletin(String)
        case segue(String)
    }

    private let infoService: InfoServicing
    private let sanityCheckService: SanityCheckServicing

    private(set) var notifications: [CampusNotification] = []
    private(set) var sanityCheckOn = true

    init(infoService: InfoServicing, sanityCheckService: SanityCheckServicing) {
        self.infoService = infoService
        self.sanityCheckService = sanityCheckService
    }

    func loadMetadata() async {
        if case let .success(cached) = await infoService.fetchNotifications() {
            notifications = cached.value
        }
        if case let .success(check) = await sanityCheckService.fetch() {
            sanityCheckOn = check.isStaging
        }
    }

    func badgeNumber(pendingReminderCount: Int = ReminderStateStore.pendingReminderCount()) -> Int {
        pendingReminderCount > 0 ? pendingReminderCount : -1
    }

    func detailText(for row: Int) -> String {
        HomeItem.local[row].detailText
    }

    func destination(for row: Int) -> Destination {
        let segue = HomeItem.local[row].segue

        switch segue {
        case "showUpass":
            return .upass
        case "showFood":
            return .food
        case "showCalendar":
            return .calendar
        case "showParking":
            return .parking
        case "showBulletin":
            if
                let first = notifications.first,
                Self.shouldRouteBulletinToWebView(notification: first, sanityCheckOn: sanityCheckOn)
            {
                return .bulletin(first.notificationID)
            }
            return .segue(segue)
        default:
            return .segue(segue)
        }
    }

    static func shouldRouteBulletinToWebView(notification: CampusNotification?, sanityCheckOn: Bool) -> Bool {
        guard let notification else { return false }
        return sanityCheckOn && (notification.content.contains("COVID") || notification.title.contains("COVID"))
    }
}
