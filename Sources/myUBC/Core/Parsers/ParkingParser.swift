//
//  ParkingParser.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation
import SwiftSoup

enum ParkingParser {
    static func parse(html: String) throws -> [ParkingAnnotation] {
        let doc: Document = try SwiftSoup.parse(html)
        let content = try doc.getElementById(Constants.parkingIDSelector)
            ?? doc.getElementById("block-parking-parkingavailability")
            ?? doc.getElementsByClass("block-ubc-parking-availability").first()
        guard let content else {
            throw AppError.parsing
        }

        let wrappers = try content.getElementsByClass("inner-wrapper").array()
        var result: [ParkingAnnotation] = []

        for wrapper in wrappers {
            if !wrapper.children().hasClass("name") { continue }
            let name = try wrapper.getElementsByClass("name").text()
            let lotName: ParkingNames
            switch name {
            case "North": lotName = .north
            case "West": lotName = .west
            case "Rose": lotName = .rose
            case "Health": lotName = .health
            case "Fraser": lotName = .fraser
            case "Thunderbird": lotName = .thunder
            default: lotName = .unknown
            }

            var parkingStatus: ParkingStatus = .unkown
            if wrapper.children().hasClass("park percent green") {
                parkingStatus = .good
            } else if wrapper.children().hasClass("park percent orange") {
                parkingStatus = .limited
            } else if wrapper.children().hasClass("park percent red") {
                parkingStatus = .full
            }

            var evStatus: ParkingStatus = .unkown
            if wrapper.children().hasClass("ev percent green") {
                evStatus = .good
            } else if wrapper.children().hasClass("ev percent orange") {
                evStatus = .limited
            } else if wrapper.children().hasClass("ev percent red") {
                evStatus = .full
            }

            result.append(ParkingAnnotation(lotName: lotName, status: [parkingStatus, evStatus]))
        }

        return result
    }
}
