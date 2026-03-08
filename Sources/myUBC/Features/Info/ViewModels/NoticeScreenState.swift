//
//  NoticeScreenState.swift
//  myUBC
//
//  Created by myUBC on 2025-07-07.
//

import Foundation

struct NoticeScreenState {
    private(set) var notifications: [CampusNotification] = []
    private(set) var wasLastUpdateSuccessful = false
    private(set) var lastUpdated: Date?
    private(set) var banner: CacheBanner?

    var rowCount: Int {
        notifications.count + 1
    }

    var footerMessage: String? {
        banner?.message
    }

    var showsTimestampLabel: Bool {
        banner == nil
    }

    mutating func beginRefresh() {
        notifications = []
    }

    mutating func applySuccess(notifications: [CampusNotification], lastUpdated: Date?, banner: CacheBanner?) {
        self.notifications = notifications
        self.lastUpdated = lastUpdated
        self.banner = banner
        wasLastUpdateSuccessful = true
    }

    mutating func applyFailure(lastUpdated: Date?, banner: CacheBanner?) {
        notifications = []
        self.lastUpdated = lastUpdated
        self.banner = banner
        wasLastUpdateSuccessful = false
    }
}
