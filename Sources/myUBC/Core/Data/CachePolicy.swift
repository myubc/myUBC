//
//  CachePolicy.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

enum CacheTTL {
    static let food: TimeInterval = 30 * 60
    static let parking: TimeInterval = 10 * 60
    static let info: TimeInterval = 30 * 60
    static let calendar: TimeInterval = 60 * 60
    static let library: TimeInterval = 60 * 60
    static let foodDetail: TimeInterval = 12 * 60 * 60
}

struct CachePolicy {
    let key: String
    let ttl: TimeInterval
    let maxStale: TimeInterval

    func isExpired(since date: Date) -> Bool {
        Date().timeIntervalSince(date) > ttl
    }

    func isTooStale(since date: Date) -> Bool {
        Date().timeIntervalSince(date) > maxStale
    }

    static let food = CachePolicy(key: "food.locations", ttl: CacheTTL.food, maxStale: 6 * 60 * 60)
    static let parking = CachePolicy(key: "parking.lots", ttl: CacheTTL.parking, maxStale: 60 * 60)
    static let info = CachePolicy(key: "info.notifications", ttl: CacheTTL.info, maxStale: 6 * 60 * 60)
    static let calendar = CachePolicy(key: "calendar.events", ttl: CacheTTL.calendar, maxStale: 24 * 60 * 60)
    static let library = CachePolicy(key: "library.equipment", ttl: CacheTTL.library, maxStale: 24 * 60 * 60)
    static let foodDetail = CachePolicy(key: "food.detail", ttl: CacheTTL.foodDetail, maxStale: 7 * 24 * 60 * 60)
}
