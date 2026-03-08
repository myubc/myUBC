//
//  CachedValue.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

struct CachedValue<T> {
    let value: T
    let isStale: Bool
    let isFromCache: Bool
    let hadNetworkError: Bool
    let lastUpdated: Date?
    let networkError: AppError?
}
