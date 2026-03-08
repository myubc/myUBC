//
//  FoodDetailViewModel.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

@MainActor
final class FoodDetailViewModel {
    private let service: FoodDetailServicing

    private(set) var detail: FoodDetailItem?
    private(set) var banner: CacheBanner?

    init(service: FoodDetailServicing) {
        self.service = service
    }

    func load(url: String, forceRefresh: Bool = false) async -> Result<Void, AppError> {
        let result = await service.fetchDetails(url: url, forceRefresh: forceRefresh)
        switch result {
        case let .success(cached):
            detail = cached.value
            banner = CacheBanner.from(
                lastUpdated: cached.lastUpdated,
                isStale: cached.isStale,
                isFromCache: cached.isFromCache,
                networkError: cached.networkError
            )
            return .success(())
        case let .failure(error):
            banner = CacheBanner.from(lastUpdated: nil, isStale: false, isFromCache: false, networkError: error)
            return .failure(error)
        }
    }
}
