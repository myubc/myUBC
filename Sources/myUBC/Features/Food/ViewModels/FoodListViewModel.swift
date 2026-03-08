//
//  FoodListViewModel.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

@MainActor
final class FoodListViewModel {
    private let service: FoodServicing

    private(set) var foods: [FoodLocation] = []
    private(set) var banner: CacheBanner?
    private(set) var lastResultWasCached = false
    private(set) var lastUpdated: Date?

    init(service: FoodServicing) {
        self.service = service
    }

    func load(forceRefresh: Bool = false) async -> Result<Void, AppError> {
        let result = await service.fetchLocations(forceRefresh: forceRefresh)
        switch result {
        case let .success(cached):
            foods = cached.value
            lastUpdated = cached.lastUpdated
            banner = CacheBanner.from(
                lastUpdated: cached.lastUpdated,
                isStale: cached.isStale,
                isFromCache: cached.isFromCache,
                networkError: cached.networkError
            )
            lastResultWasCached = cached.isFromCache
            return .success(())
        case let .failure(error):
            lastUpdated = nil
            banner = CacheBanner.from(lastUpdated: nil, isStale: false, isFromCache: false, networkError: error)
            return .failure(error)
        }
    }
}
