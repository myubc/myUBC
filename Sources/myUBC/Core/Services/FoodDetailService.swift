//
//  FoodDetailService.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

protocol FoodDetailServicing {
    func fetchDetails(url: String, forceRefresh: Bool) async -> Result<CachedValue<FoodDetailItem>, AppError>
}

extension FoodDetailServicing {
    func fetchDetails(url: String) async -> Result<CachedValue<FoodDetailItem>, AppError> {
        await fetchDetails(url: url, forceRefresh: false)
    }
}

actor FoodDetailService: FoodDetailServicing {
    private let client: NetworkClient
    private let cache: CacheStore

    init(client: NetworkClient, cache: CacheStore) {
        self.client = client
        self.cache = cache
    }

    func fetchDetails(url: String, forceRefresh: Bool = false) async -> Result<CachedValue<FoodDetailItem>, AppError> {
        guard let url = URL(string: url) else {
            return .failure(.invalidResponse)
        }
        let keySuffix = Data(url.absoluteString.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        let cacheKey = CachePolicy.foodDetail.key + "." + keySuffix
        let cachedEntry = await cache.loadEntry(FoodDetailItem.self, policy: CachePolicy(key: cacheKey, ttl: CacheTTL.foodDetail, maxStale: 7 * 24 * 60 * 60))
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
            let item = try FoodDetailParser.parse(html: html)
            await cache.save(item, key: cacheKey)
            return .success(CachedValue(
                value: item,
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            ))
        } catch {
            AppLogger.network.error("Food detail fetch failed: \((error as NSError).localizedDescription, privacy: .public)")
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
