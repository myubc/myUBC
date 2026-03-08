//
//  FoodLocation.swift
//  myUBC
//
//  Created by myUBC on 2020-03-26.
//

import Foundation

struct FoodLocation: Hashable, Codable {
    var name: String
    var isOpen: Bool
    var statusText: String
    var slug: String = ""
    var url: String = ""
    var address: String = ""
    var rating: Int = 0
}
