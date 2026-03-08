//
//  HomeItem.swift
//  myUBC
//
//  Created by myUBC on 2020-03-12.
//

import Foundation

struct HomeItem: Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let segue: String
    let detailText: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension HomeItem {
    static var local: [HomeItem] {
        return Constants.homeItems
    }
}
