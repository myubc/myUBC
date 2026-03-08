//
//  ParkingService.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

protocol ParkingServicing {
    func fetchParking(forceRefresh: Bool) async -> Result<CachedValue<[ParkingAnnotation]>, AppError>
}

extension ParkingServicing {
    func fetchParking() async -> Result<CachedValue<[ParkingAnnotation]>, AppError> {
        await fetchParking(forceRefresh: false)
    }
}

actor ParkingService: ParkingServicing {
    private let client: NetworkClient
    private let cache: CacheStore

    init(client: NetworkClient, cache: CacheStore) {
        self.client = client
        self.cache = cache
    }

    func fetchParking(forceRefresh: Bool = false) async -> Result<CachedValue<[ParkingAnnotation]>, AppError> {
        let cachedEntry = await cache.loadEntry([ParkingLotSnapshot].self, policy: .parking)
        if let cachedEntry, !forceRefresh, !cachedEntry.isStale {
            let lots = cachedEntry.value.map { ParkingAnnotation(snapshot: $0) }
            return .success(CachedValue(
                value: lots,
                isStale: false,
                isFromCache: true,
                hadNetworkError: false,
                lastUpdated: cachedEntry.timestamp,
                networkError: nil
            ))
        }

        guard let url = URL(string: "https://parking.ubc.ca/") else {
            return .failure(.invalidResponse)
        }
        do {
            let data = try await client.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                return .failure(.invalidResponse)
            }
            let lots = try ParkingParser.parse(html: html)
            let snapshots = lots.map { ParkingLotSnapshot(lotName: $0.lotName, status: $0.status) }
            await cache.save(snapshots, key: CachePolicy.parking.key)
            return .success(CachedValue(
                value: lots,
                isStale: false,
                isFromCache: false,
                hadNetworkError: false,
                lastUpdated: Date(),
                networkError: nil
            ))
        } catch {
            AppLogger.network.error("Parking fetch failed: \((error as NSError).localizedDescription, privacy: .public)")
            if let cachedEntry {
                let mapped = AppError.from(error)
                let lots = cachedEntry.value.map { ParkingAnnotation(snapshot: $0) }
                return .success(CachedValue(
                    value: lots,
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
