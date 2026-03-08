//
//  LibraryService.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

protocol LibraryServicing {
    func fetchLibrary(forceRefresh: Bool) async -> Result<CachedValue<LibraryModel>, AppError>
}

extension LibraryServicing {
    func fetchLibrary() async -> Result<CachedValue<LibraryModel>, AppError> {
        await fetchLibrary(forceRefresh: false)
    }
}

actor LibraryService: LibraryServicing {
    private let client: NetworkClient
    private let cache: CacheStore

    init(client: NetworkClient, cache: CacheStore) {
        self.client = client
        self.cache = cache
    }

    func fetchLibrary(forceRefresh: Bool = false) async -> Result<CachedValue<LibraryModel>, AppError> {
        let cachedEntry = await cache.loadEntry(LibraryModel.self, policy: .library)
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
        let devices: [Device] = [.IPhone1, .IPhone2, .Andriod1, .Andriod2, .Mac1, .Mac2]
        let model = LibraryModel()
        var hadError = false
        var successCount = 0

        await withTaskGroup(of: (Device, [Equipment]?).self) { group in
            for device in devices {
                group.addTask { [client] in
                    guard let link = LibraryService.link(for: device), let url = URL(string: link) else {
                        return (device, nil)
                    }
                    do {
                        let data = try await client.data(from: url)
                        guard let html = String(data: data, encoding: .utf8) else { return (device, nil) }
                        let parsed = try LibraryParser.parse(html: html, device: device)
                        return (device, parsed)
                    } catch {
                        return (device, nil)
                    }
                }
            }

            for await(device, equipment) in group {
                guard let equipment else {
                    hadError = true
                    continue
                }
                successCount += 1
                switch device {
                case .IPhone1:
                    model.iphones1 = equipment
                case .IPhone2:
                    model.iphones2 = equipment
                case .Andriod1:
                    model.andriods1 = equipment
                case .Andriod2:
                    model.andriods2 = equipment
                case .Mac1:
                    model.macs1 = equipment
                case .Mac2:
                    model.macs2 = equipment
                default:
                    break
                }
            }
        }

        if successCount == 0 {
            if let cachedEntry {
                return .success(CachedValue(
                    value: cachedEntry.value,
                    isStale: cachedEntry.isStale,
                    isFromCache: true,
                    hadNetworkError: true,
                    lastUpdated: cachedEntry.timestamp,
                    networkError: .unknown
                ))
            }
            return .failure(.unknown)
        }

        await cache.save(model, key: CachePolicy.library.key)
        return .success(CachedValue(
            value: model,
            isStale: false,
            isFromCache: false,
            hadNetworkError: hadError,
            lastUpdated: Date(),
            networkError: hadError ? .unknown : nil
        ))
    }

    private static func link(for device: Device) -> String? {
        switch device {
        case .IPhone1:
            return Constants.libraryURL_iphone1
        case .IPhone2:
            return Constants.libraryURL_iphone2
        case .Andriod1:
            return Constants.libraryURL_android1
        case .Andriod2:
            return Constants.libraryURL_android2
        case .Mac1:
            return Constants.libraryURL_mac1
        case .Mac2:
            return Constants.libraryURL_mac2
        default:
            return nil
        }
    }
}
