//
//  FoodListScreenModel.swift
//  myUBC
//
//  Created by myUBC on 2025-07-07.
//

import Foundation

@MainActor
final class FoodListScreenModel {
    private(set) var foods: [FoodLocation] = []
    private(set) var isSearching = false
    private(set) var searchQuery = ""
    private(set) var showsAll = true

    var visibleFoods: [FoodLocation] {
        if isSearching {
            return foods.filter { location in
                location.name.range(of: searchQuery, options: .caseInsensitive) != nil
            }
        }

        guard !showsAll else {
            return foods
        }

        return foods.filter(\.isOpen)
    }

    var tableRowCount: Int {
        if isSearching {
            return visibleFoods.count
        }
        return max(visibleFoods.count, 1) + 1
    }

    var isShowingLoadingEmptyState: Bool {
        !isSearching && foods.isEmpty
    }

    func updateFoods(_ foods: [FoodLocation]) {
        self.foods = foods
    }

    func setSearching(_ isSearching: Bool) {
        self.isSearching = isSearching
        if !isSearching {
            searchQuery = ""
        }
    }

    func setSearchQuery(_ searchQuery: String) {
        self.searchQuery = searchQuery
    }

    func setShowAll(_ showsAll: Bool) {
        self.showsAll = showsAll
    }

    func food(atRow row: Int) -> FoodLocation? {
        let index = isSearching ? row : row - 1
        guard index >= 0, index < visibleFoods.count else {
            return nil
        }
        return visibleFoods[index]
    }
}
