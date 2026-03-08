//
//  NoticeViewModel.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

@MainActor
final class NoticeViewModel {
    private let service: InfoServicing

    private(set) var notifications: [CampusNotification] = []
    private(set) var banner: CacheBanner?
    private(set) var lastUpdated: Date?

    init(service: InfoServicing) {
        self.service = service
    }

    func load(forceRefresh: Bool = false) async -> Result<Void, AppError> {
        let result = await service.fetchNotifications(forceRefresh: forceRefresh)
        switch result {
        case let .success(cached):
            notifications = cached.value
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
