//
//  FoodItem.swift
//  myUBC
//
//  Created by myUBC on 2020-05-10.
//

import Foundation

struct FoodItem: Codable {
    var spaceTitle: String
    var url: String
    var tvalue: String
    var address: String
    var rating: Int
}

extension FoodItem {
    static var local: [FoodItem] {
        return Constants.foodItems
    }
}
