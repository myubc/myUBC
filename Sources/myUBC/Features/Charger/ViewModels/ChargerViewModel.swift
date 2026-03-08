//
//  ChargerViewModel.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

@MainActor
final class ChargerViewModel {
    private let service: LibraryServicing

    private(set) var model = LibraryModel()
    private(set) var banner: CacheBanner?
    private(set) var lastUpdated: Date?

    init(service: LibraryServicing) {
        self.service = service
    }

    func load(forceRefresh: Bool = false) async -> Result<Void, AppError> {
        let result = await service.fetchLibrary(forceRefresh: forceRefresh)
        switch result {
        case let .success(cached):
            model = cached.value
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
