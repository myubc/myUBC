//
//  FoodCatalog.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

enum FoodCatalog {
    static func load(bundle: Bundle = .main) -> [FoodItem] {
        guard
            let url = bundle.url(forResource: "FoodPlaces", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let array = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]]
        else {
            return []
        }

        let mapped: [(order: Int, item: FoodItem)] = array.compactMap { dict in
            let title = (dict["spaceTitle"] as? String) ?? (dict["displayName"] as? String)
            guard
                let spaceTitle = title,
                let url = dict["url"] as? String
            else { return nil }
            let tvalue = dict["tvalue"] as? String ?? ""
            let address = dict["address"] as? String ?? ""
            let rating = dict["rating"] as? Int ?? 0
            let order = dict["sortOrder"] as? Int ?? 0
            let item = FoodItem(spaceTitle: spaceTitle, url: url, tvalue: tvalue, address: address, rating: rating)
            return (order, item)
        }

        return mapped.sorted(by: { $0.order < $1.order }).map { $0.item }
    }

    static func resolve(from items: [FoodItem], slug: String, url: String, title: String) -> FoodItem? {
        let candidateSlug = normalizedSlug(slug.isEmpty ? urlSlug(from: url) : slug)
        if
            !candidateSlug.isEmpty,
            let slugMatch = items.first(where: { normalizedSlug(urlSlug(from: $0.url)) == candidateSlug })
        {
            return slugMatch
        }

        let normalizedTitle = normalizedName(title)
        if !normalizedTitle.isEmpty {
            if let exact = items.first(where: { normalizedName($0.spaceTitle) == normalizedTitle }) {
                return exact
            }
            if
                let contain = items.first(where: {
                    let candidate = normalizedName($0.spaceTitle)
                    return candidate.contains(normalizedTitle) || normalizedTitle.contains(candidate)
                })
            {
                return contain
            }
        }
        return nil
    }

    private static func urlSlug(from urlString: String) -> String {
        guard let components = URLComponents(string: urlString) else { return "" }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let last = path.split(separator: "/").last else { return "" }
        return String(last)
    }

    private static func normalizedSlug(_ value: String) -> String {
        normalizedName(value).replacingOccurrences(of: " ", with: "-")
    }

    private static func normalizedName(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
