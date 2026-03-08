//
//  LibraryConstants.swift
//  myUBC
//
//  Created by myUBC on 2020-01-23.
//

import Foundation
import UIKit

enum LibraryConstants {
    static let data = [
        0: ["title": "iPhone Chargers", "location": "Irving K. Barber (IKB) Learning Centre", "img": "iphone1_png"],
        1: ["title": "iPhone Chargers", "location": "David Lam Research Library", "img": "iphone2_png"],
        2: ["title": "Android Chargers", "location": "Irving K. Barber (IKB) Learning Centre", "img": "android1_png"],
        3: ["title": "Android Chargers", "location": "David Lam Research Library", "img": "android2_png"],
        4: ["title": "Mac/PC Chargers", "location": "Irving K. Barber (IKB) Learning Centre", "img": "laptop1_png"],
        5: ["title": "Mac/PC Chargers", "location": "David Lam Research Library", "img": "laptop2_png"]
    ]
        as [Int: [String: String]]

    static let backgroundColors: [UIColor] = [#colorLiteral(red: 0.00015113056, green: 0.3586666584, blue: 0.6652547121, alpha: 1), #colorLiteral(red: 0.0006913500838, green: 0.5138331652, blue: 0.7626002431, alpha: 1), #colorLiteral(red: 0.2162669897, green: 0.7064954638, blue: 0.8986544013, alpha: 1), #colorLiteral(red: 0.5744345784, green: 0.8317165971, blue: 0.9124664664, alpha: 1), #colorLiteral(red: 0.6125244225, green: 0.8822660298, blue: 0.7868683191, alpha: 1), #colorLiteral(red: 0.6002732812, green: 0.8319691893, blue: 0.5774991955, alpha: 1)]
}
