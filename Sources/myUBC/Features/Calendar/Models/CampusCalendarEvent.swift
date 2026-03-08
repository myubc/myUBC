//
//  CampusCalendarEvent.swift
//  myUBC
//
//  Created by myUBC on 2021-01-31.
//

import Foundation

struct CampusCalendarEvent: Codable {
    var date: Date = .init()
    var events: [CampusEventDetail] = []
}

struct CampusEventDetail: Codable {
    var isImportant: Bool = false
    var eventDescription: String = ""
}
