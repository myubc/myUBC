//
//  ParkingViewModel.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

@MainActor
final class ParkingViewModel {
    private let service: ParkingServicing

    private(set) var lots: [ParkingAnnotation] = []
    private(set) var banner: CacheBanner?

    init(service: ParkingServicing) {
        self.service = service
    }

    func load(forceRefresh: Bool = false) async -> Result<Void, AppError> {
        let result = await service.fetchParking(forceRefresh: forceRefresh)
        switch result {
        case let .success(cached):
            lots = cached.value
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
