//
//  FoodStatusRules.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

struct FoodStatusRules {
    let statusContainerSelectors: [String]
    let statusTextSelectors: [String]
    let openClassTokens: [String]
    let closedClassTokens: [String]
    let openTextPatterns: [String]
    let closedTextPatterns: [String]

    static func load(bundle: Bundle = .main) -> FoodStatusRules {
        guard
            let url = bundle.url(forResource: "FoodParsingRules", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else {
            return FoodStatusRules.defaultRules
        }

        func array(_ key: String) -> [String] {
            (dict[key] as? [String]) ?? []
        }

        return FoodStatusRules(
            statusContainerSelectors: array("statusContainerSelectors"),
            statusTextSelectors: array("statusTextSelectors"),
            openClassTokens: array("openClassTokens"),
            closedClassTokens: array("closedClassTokens"),
            openTextPatterns: array("openTextPatterns"),
            closedTextPatterns: array("closedTextPatterns")
        )
    }

    static let defaultRules = FoodStatusRules(
        statusContainerSelectors: [".mb-bhi-display", "span[class*=mb-bhi]"],
        statusTextSelectors: [".mb-bhi-oc-text"],
        openClassTokens: ["mb-bhi-open"],
        closedClassTokens: ["mb-bhi-closed", "mb-bhi-close"],
        openTextPatterns: ["open till", "open until", "open"],
        closedTextPatterns: ["closed", "opens", "opening"]
    )
}
