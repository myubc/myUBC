//
//  CacheStore.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

actor CacheStore {
    private let fileManager = FileManager.default
    private let baseURL: URL

    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        baseURL = caches.appendingPathComponent("myUBC.cache", isDirectory: true)
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    func load<T: Codable>(_ type: T.Type, key: String, maxAge: TimeInterval) -> T? {
        let url = path(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let envelope = try? JSONDecoder().decode(CacheEnvelope<T>.self, from: data) else { return nil }
        let age = Date().timeIntervalSince(envelope.timestamp)
        guard age <= maxAge else { return nil }
        return envelope.value
    }

    func loadEntry<T: Codable>(_: T.Type, policy: CachePolicy) -> CacheEntry<T>? {
        let url = path(for: policy.key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let envelope = try? JSONDecoder().decode(CacheEnvelope<T>.self, from: data) else { return nil }
        let isStale = policy.isExpired(since: envelope.timestamp)
        let isTooStale = policy.isTooStale(since: envelope.timestamp)
        guard !isTooStale else { return nil }
        return CacheEntry(value: envelope.value, timestamp: envelope.timestamp, isStale: isStale)
    }

    func save<T: Codable>(_ value: T, key: String) {
        let url = path(for: key)
        let envelope = CacheEnvelope(timestamp: Date(), value: value)
        if let data = try? JSONEncoder().encode(envelope) {
            try? data.write(to: url, options: Data.WritingOptions.atomic)
        }
    }

    func invalidate(key: String) {
        let url = path(for: key)
        try? fileManager.removeItem(at: url)
    }

    func prune(maxAge: TimeInterval) {
        guard let contents = try? fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }
        let cutoff = Date().addingTimeInterval(-maxAge)
        for url in contents {
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
            if let modified = values?.contentModificationDate, modified < cutoff {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private func path(for key: String) -> URL {
        baseURL.appendingPathComponent(key + ".json")
    }
}

private struct CacheEnvelope<T: Codable>: Codable {
    let timestamp: Date
    let value: T
}

struct CacheEntry<T> {
    let value: T
    let timestamp: Date
    let isStale: Bool
}
