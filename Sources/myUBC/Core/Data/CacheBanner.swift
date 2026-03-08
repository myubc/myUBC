//
//  CacheBanner.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

struct CacheBanner {
    let message: String
    let style: StatusBannerStyle

    static func from(lastUpdated: Date?, isStale: Bool, isFromCache: Bool, networkError: AppError?) -> CacheBanner? {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        if let error = networkError, case .offline = error {
            let relative = lastUpdated.map { formatter.localizedString(for: $0, relativeTo: Date()) } ?? ""
            let template = NSLocalizedString("banner.lastUpdated", comment: "Last updated template")
            let lastUpdatedText = relative.isEmpty ? "" : String(format: template, relative)
            let message = [error.userMessage, lastUpdatedText].filter { !$0.isEmpty }.joined(separator: " ")
            return CacheBanner(message: message, style: .offline)
        }

        if isStale || isFromCache, let lastUpdated {
            let relative = formatter.localizedString(for: lastUpdated, relativeTo: Date())
            let template = NSLocalizedString("banner.lastUpdated", comment: "Last updated template")
            let message = String(format: template, relative)
            return CacheBanner(message: message, style: isStale ? .stale : .info)
        }

        return nil
    }

    static func lastUpdatedMessage(from date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        let template = NSLocalizedString("banner.lastUpdated", comment: "Last updated template")
        return String(format: template, relative)
    }
}
