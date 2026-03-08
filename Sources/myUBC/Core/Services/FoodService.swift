//
//  FoodService.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

protocol FoodServicing {
    func fetchLocations(forceRefresh: Bool) async -> Result<CachedValue<[FoodLocation]>, AppError>
}

extension FoodServicing {
    func fetchLocations() async -> Result<CachedValue<[FoodLocation]>, AppError> {
        await fetchLocations(forceRefresh: false)
    }
}

actor FoodService: FoodServicing {
    private let client: NetworkClient
    private let cache: CacheStore

    init(client: NetworkClient, cache: CacheStore) {
        self.client = client
        self.cache = cache
    }

    func fetchLocations(forceRefresh: Bool = false) async -> Result<CachedValue<[FoodLocation]>, AppError> {
        let cachedEntry = await cache.loadEntry([FoodLocation].self, policy: .food)
        let catalog = FoodCatalog.load()
        if
            let cachedEntry, !forceRefresh, !cachedEntry.isStale,
            cachedEntry.value.allSatisfy({ !$0.url.isEmpty })
        {
            let hydrated = hydrate(cachedEntry.value, with: catalog)
            if hydrated != cachedEntry.value {
                await cache.save(hydrated, key: CachePolicy.food.key)
            }
            return .success(CachedValue(
                value: hydrated,
                isStale: false,
                isFromCache: true,
                hadNetworkError: false,
                lastUpdated: cachedEntry.timestamp,
                networkError: nil
            ))
        }

        do {
            guard let feedURL = URL(string: Constants.foodLink) else {
                return .failure(.invalidResponse)
            }
            var request = URLRequest(url: feedURL)
            request.httpMethod = "GET"
            request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("https://food.ubc.ca/", forHTTPHeaderField: "Referer")
            let data = try await client.data(for: request, policy: .noRetry)
            guard let html = String(data: data, encoding: .utf8) else {
                return .failure(.invalidResponse)
            }
            let entries = FoodStatusParser.parseFeedStatuses(html: html)
            let results = mapStatuses(entries, catalog: catalog)

            if !results.isEmpty {
                await cache.save(results, key: CachePolicy.food.key)
                return .success(CachedValue(
                    value: results,
                    isStale: false,
                    isFromCache: false,
                    hadNetworkError: false,
                    lastUpdated: Date(),
                    networkError: nil
                ))
            }
        } catch {
            AppLogger.network.error("Food feed fetch failed: \((error as NSError).localizedDescription, privacy: .public)")
            if let cachedEntry {
                return .success(CachedValue(
                    value: cachedEntry.value,
                    isStale: cachedEntry.isStale,
                    isFromCache: true,
                    hadNetworkError: true,
                    lastUpdated: cachedEntry.timestamp,
                    networkError: AppError.from(error)
                ))
            }
            return .failure(AppError.from(error))
        }

        return .failure(.parsing)
    }

    private func mapStatuses(_ entries: [FoodStatusParser.FeedStatusEntry], catalog: [FoodItem]) -> [FoodLocation] {
        return entries.map { entry in
            let detail = FoodCatalog.resolve(from: catalog, slug: entry.slug, url: entry.url, title: entry.title)
            return FoodLocation(
                name: detail?.spaceTitle ?? entry.title,
                isOpen: entry.isOpen,
                statusText: entry.statusText,
                slug: entry.slug,
                url: entry.url,
                address: detail?.address ?? "",
                rating: detail?.rating ?? 0
            )
        }
    }

    private func hydrate(_ locations: [FoodLocation], with catalog: [FoodItem]) -> [FoodLocation] {
        locations.map { location in
            guard location.address.isEmpty || location.rating == 0 else { return location }
            guard let detail = FoodCatalog.resolve(from: catalog, slug: location.slug, url: location.url, title: location.name) else {
                return location
            }
            var updated = location
            if updated.address.isEmpty {
                updated.address = detail.address
            }
            if updated.rating == 0 {
                updated.rating = detail.rating
            }
            if updated.name.isEmpty {
                updated.name = detail.spaceTitle
            }
            return updated
        }
    }
}
