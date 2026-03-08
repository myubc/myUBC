//
//  FoodPlaceCatalog.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

struct FoodPlaceRecord: Hashable {
    let id: String
    let displayName: String
    let url: String
    let category: String
    let sortOrder: Int
    let iconName: String
    let widgetDefault: Bool
}

enum FoodPlaceCatalog {
    static func loadDefaults() -> [FoodPlaceRecord] {
        guard
            let url = Bundle.main.url(forResource: "FoodPlaces", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let array = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]]
        else {
            return []
        }
        return array.compactMap { dict in
            guard
                let id = dict["id"] as? String,
                let name = dict["displayName"] as? String,
                let link = dict["url"] as? String
            else { return nil }
            let category = dict["category"] as? String ?? ""
            let iconName = dict["iconName"] as? String ?? ""
            let sortOrder = dict["sortOrder"] as? Int ?? 0
            let widgetDefault = dict["widgetDefault"] as? Bool ?? false
            return FoodPlaceRecord(
                id: id,
                displayName: name,
                url: link,
                category: category,
                sortOrder: sortOrder,
                iconName: iconName,
                widgetDefault: widgetDefault
            )
        }.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    static func asDictionary() -> [String: String] {
        Dictionary(uniqueKeysWithValues: loadDefaults().map { ($0.displayName, $0.url) })
    }
}
