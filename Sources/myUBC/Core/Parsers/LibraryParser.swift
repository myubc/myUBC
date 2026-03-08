//
//  LibraryParser.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation
import SwiftSoup

enum LibraryParser {
    static func parse(html: String, device: Device) throws -> [Equipment] {
        var result = [Equipment]()
        let doc: Document = try SwiftSoup.parse(html)
        let content: Elements = try doc.select(Constants.selector)
        let sections: [Element] = content.array()

        for section in sections {
            let rows = try section.getElementsByClass(Constants.classname)
            var location = ""
            var callType = ""
            var totalNum = ""
            var status = ""
            for (i, row) in rows.array().enumerated() {
                switch i {
                case 0:
                    location = try row.text()
                case 1:
                    callType = try row.text()
                case 2:
                    totalNum = try row.text()
                case 3:
                    status = try row.html()
                default:
                    break
                }
            }

            var statusArray = [EquipmentStatus]()
            if
                status.contains("On loan") || status.contains("Returned") || status.contains("Overdue") || status.contains("Lost") || status
                    .contains("Available")
            {
                let rawText = status.components(separatedBy: "<br>")
                for item in rawText {
                    if item == "" { continue }
                    var note = ""
                    var date: Date?
                    if let parsed = matches(for: Constants.regular_date, in: item).first {
                        let format = "MM-dd-yyyy HH:mm:ss"
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeZone = TimeZone(identifier: "America/Vancouver")
                        dateFormatter.locale = Locale(identifier: "en_CA")
                        dateFormatter.calendar = Calendar(identifier: .gregorian)
                        dateFormatter.dateFormat = format
                        date = dateFormatter.date(from: parsed)

                        if date == nil {
                            let format = "MM-dd-yyyy"
                            let dateFormatter = DateFormatter()
                            dateFormatter.timeZone = TimeZone(identifier: "America/Vancouver")
                            dateFormatter.locale = Locale(identifier: "en_CA")
                            dateFormatter.calendar = Calendar(identifier: .gregorian)
                            dateFormatter.dateFormat = format
                            date = dateFormatter.date(from: parsed)
                        }
                    }

                    var isAvailable = item.contains("Returned") ? true : false
                    var ref = item.components(separatedBy: " ").first
                    if item.contains("Overdue") { note = "Overdue" } else if item.contains("Lost") { note = "Lost" } else if item.contains("Available") {
                        note = "Available"
                        isAvailable = true
                    }
                    if ref == "Available" { ref = " - " }
                    statusArray.append(EquipmentStatus(isAvailable: isAvailable, referenceNo: ref, date: date, note: note))
                }
            }

            result.append(Equipment(
                type: device,
                name: callType,
                location: nameCleanup(location),
                total: totalNum,
                details: statusArray
            ))
        }

        return result
    }

    private static func nameCleanup(_ name: String) -> String {
        name.replacingOccurrences(of: "Where is this?", with: "")
    }

    private static func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map { String(text[Range($0.range, in: text)!]) }
        } catch {
            return []
        }
    }
}
