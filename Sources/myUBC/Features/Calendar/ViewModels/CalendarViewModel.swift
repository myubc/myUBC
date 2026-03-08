//
//  CalendarViewModel.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

@MainActor
final class CalendarViewModel {
    private let service: CalendarServicing

    private(set) var events: [CampusCalendarEvent] = []
    private(set) var banner: CacheBanner?
    private(set) var lastUpdated: Date?

    init(service: CalendarServicing) {
        self.service = service
    }

    func load(visibleMonth: Date, forceRefresh: Bool = false) async -> Result<Void, AppError> {
        let result = await service.fetchMonth(visibleMonth, forceRefresh: forceRefresh)
        switch result {
        case let .success(cached):
            events = cached.value
            lastUpdated = cached.lastUpdated
            banner = CacheBanner.from(
                lastUpdated: cached.lastUpdated,
                isStale: cached.isStale,
                isFromCache: cached.isFromCache,
                networkError: cached.networkError
            )
            return .success(())
        case let .failure(error):
            lastUpdated = nil
            banner = CacheBanner.from(lastUpdated: nil, isStale: false, isFromCache: false, networkError: error)
            return .failure(error)
        }
    }
}
