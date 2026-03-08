//
//  FeatureFlags.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

struct FeatureFlags {
    let showFood: Bool
    let showCharger: Bool
    let showCalendar: Bool
    let showParking: Bool
    let showUpass: Bool
    let showInfo: Bool
    let enableWidgets: Bool

    static let shared = FeatureFlags.load()

    static func load(bundle: Bundle = .main) -> FeatureFlags {
        guard
            let url = bundle.url(forResource: "FeatureFlags", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else {
            return FeatureFlags.defaults()
        }

        return FeatureFlags(
            showFood: dict["showFood"] as? Bool ?? true,
            showCharger: dict["showCharger"] as? Bool ?? true,
            showCalendar: dict["showCalendar"] as? Bool ?? true,
            showParking: dict["showParking"] as? Bool ?? true,
            showUpass: dict["showUpass"] as? Bool ?? true,
            showInfo: dict["showInfo"] as? Bool ?? true,
            enableWidgets: dict["enableWidgets"] as? Bool ?? true
        )
    }

    static func defaults() -> FeatureFlags {
        FeatureFlags(
            showFood: true,
            showCharger: true,
            showCalendar: true,
            showParking: true,
            showUpass: true,
            showInfo: true,
            enableWidgets: true
        )
    }
}
