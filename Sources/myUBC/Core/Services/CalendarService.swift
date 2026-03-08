//
//  CalendarService.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

protocol CalendarServicing {
    func fetchMonth(_ visibleMonth: Date, forceRefresh: Bool) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError>
}

extension CalendarServicing {
    func fetchMonth(_ visibleMonth: Date) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
        await fetchMonth(visibleMonth, forceRefresh: false)
    }
}

actor CalendarService: CalendarServicing {
    private let client: NetworkClient
    private let cache: CacheStore

    init(client: NetworkClient, cache: CacheStore) {
        self.client = client
        self.cache = cache
    }

    func fetchMonth(_ visibleMonth: Date, forceRefresh: Bool = false) async -> Result<CachedValue<[CampusCalendarEvent]>, AppError> {
        let month = Self.pacificCalendar.component(.month, from: visibleMonth)
        let year = Self.pacificCalendar.component(.year, from: visibleMonth)
        let url = CalendarSource.sourceURL(for: visibleMonth)
        let policy = CachePolicy(key: "\(CachePolicy.calendar.key).\(year)-\(month)", ttl: CacheTTL.calendar, maxStale: 24 * 60 * 60)
        let cachedEntry = await cache.loadEntry([CampusCalendarEvent].self, policy: policy)
        if let cachedEntry, !forceRefresh, !cachedEntry.isStale {
            return .success(CachedValue(
                value: cachedEntry.value,
                isStale: false,
                isFromCache: true,
                hadNetworkError: false,
                lastUpdated: cachedEntry.timestamp,
                networkError: nil
            ))
        }
        do {
            let data = try await client.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                return .failure(.invalidResponse)
            }
            let allEvents = try CalendarParser.parse(html: html)
            if allEvents.isEmpty {
                return .failure(.parsing)
            }
            let events = allEvents.filter { event in
                Self.pacificCalendar.component(.year, from: event.date) == year &&
                    Self.pacificCalendar.component(.month, from: event.date) == month
            }
            await cache.save(events, key: policy.key)
            return .success(CachedValue(
                value: events,
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            ))
        } catch {
            AppLogger.parsing.error("Calendar fetch failed: \((error as NSError).localizedDescription, privacy: .public)")
            if let cachedEntry {
                let mapped = AppError.from(error)
                return .success(CachedValue(
                    value: cachedEntry.value,
                    isStale: cachedEntry.isStale,
                    isFromCache: true,
                    hadNetworkError: true,
                    lastUpdated: cachedEntry.timestamp,
                    networkError: mapped
                ))
            }
            return .failure(AppError.from(error))
        }
    }
}

private extension CalendarService {
    static var pacificCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Vancouver") ?? .current
        return calendar
    }
}
