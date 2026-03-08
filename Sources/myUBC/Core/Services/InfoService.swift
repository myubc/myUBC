//
//  InfoService.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

protocol InfoServicing {
    func fetchNotifications(forceRefresh: Bool) async -> Result<CachedValue<[CampusNotification]>, AppError>
}

extension InfoServicing {
    func fetchNotifications() async -> Result<CachedValue<[CampusNotification]>, AppError> {
        await fetchNotifications(forceRefresh: false)
    }
}

actor InfoService: InfoServicing {
    private let client: NetworkClient
    private let cache: CacheStore

    init(client: NetworkClient, cache: CacheStore) {
        self.client = client
        self.cache = cache
    }

    func fetchNotifications(forceRefresh: Bool = false) async -> Result<CachedValue<[CampusNotification]>, AppError> {
        let cachedEntry = await cache.loadEntry([CampusNotification].self, policy: .info)
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

        guard let url = URL(string: Constants.campusInfoURL) else {
            return .failure(.invalidResponse)
        }
        do {
            let data = try await client.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                return .failure(.invalidResponse)
            }
            let notifications = try CampusNotificationParser.parse(html: html)
            await cache.save(notifications, key: CachePolicy.info.key)
            return .success(CachedValue(
                value: notifications,
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            ))
        } catch {
            AppLogger.parsing.error("Campus notification fetch failed: \((error as NSError).localizedDescription, privacy: .public)")
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
