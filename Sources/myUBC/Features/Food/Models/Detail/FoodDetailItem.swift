//
//  FoodDetailItem.swift
//  myUBC
//
//  Created by myUBC on 2020-10-18.
//

import Foundation

struct FoodDetailItem: Codable {
    var description: String
    var carryover: Bool
    var ubccard: Bool
    var mealplan: Bool
    var images: [String]
    var address: String?
}
