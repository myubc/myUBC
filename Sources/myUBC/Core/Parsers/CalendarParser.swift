//
//  CalendarParser.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation
import SwiftSoup

enum CalendarParser {
    static func parse(html: String) throws -> [CampusCalendarEvent] {
        let doc: Document = try SwiftSoup.parse(html)
        let legacy = try parseLegacy(doc: doc)
        if !legacy.isEmpty {
            return legacy
        }
        return try parseModern(doc: doc)
    }

    private static func parseLegacy(doc: Document) throws -> [CampusCalendarEvent] {
        var campusCalendarEvents: [CampusCalendarEvent] = []
        let baseView = try doc.select("#UbcMainContent")
        let dates = try baseView.select("p").array()
        let details = try baseView.select("blockquote").array()
        var overallEvents: [[CampusEventDetail]] = []

        for content in details {
            var today: [CampusEventDetail] = []
            let eventsElement = try content.html().components(separatedBy: "<br>")
            var rawEvent: [String] = []
            for event in eventsElement {
                let contentText = try SwiftSoup.parse(String(event)).text()
                if !contentText.isEmpty {
                    rawEvent.append(contentText)
                }
            }
            for event in rawEvent {
                today.append(CampusEventDetail(isImportant: false, eventDescription: event))
            }

            let importantEvents = try content.getElementsByTag("b").array()
            for importantEvent in importantEvents {
                if try importantEvent.text() != "" {
                    let str = try importantEvent.text()
                    for (index, event) in today.enumerated() {
                        if event.eventDescription.contains(str) || str.contains(event.eventDescription) {
                            today[index].isImportant = true
                        }
                    }
                }
            }
            overallEvents.append(today)
        }

        if dates.count == overallEvents.count {
            for (index, element) in dates.enumerated() {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE, d MMMM yyyy"
                if let date = try dateFormatter.date(from: element.text()) {
                    let arr = overallEvents[index]
                    campusCalendarEvents.append(CampusCalendarEvent(date: normalizedCalendarDay(from: date), events: arr))
                }
            }
        }

        return campusCalendarEvents
    }

    private static func parseModern(doc: Document) throws -> [CampusCalendarEvent] {
        var grouped: [Date: [CampusEventDetail]] = [:]
        let timeNodes = try doc.select("time.datetime").array()

        for node in timeNodes {
            let rawDate = (try? node.attr("datetime")) ?? ""
            guard let date = normalizedCalendarDay(fromISO8601: rawDate) else { continue }

            let details = detailsFor(timeNode: node)
            if details.isEmpty { continue }

            if grouped[date] == nil {
                grouped[date] = []
            }
            grouped[date]?.append(contentsOf: details)
        }

        return grouped.keys.sorted().map { date in
            CampusCalendarEvent(date: date, events: grouped[date] ?? [])
        }
    }

    private static func detailsFor(timeNode: Element) -> [CampusEventDetail] {
        var node: Element? = timeNode
        for _ in 0 ..< 8 {
            guard let current = node else { break }
            if let detailBlock = try? current.select(".field--name-field-date-details").first() {
                let paragraphs = ((try? detailBlock.select("p").array()) ?? []).compactMap {
                    ((try? $0.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                }.filter { !$0.isEmpty }
                if !paragraphs.isEmpty {
                    return paragraphs.map { CampusEventDetail(isImportant: isImportant($0), eventDescription: $0) }
                }
                let fallback = ((try? detailBlock.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !fallback.isEmpty {
                    return [CampusEventDetail(isImportant: isImportant(fallback), eventDescription: fallback)]
                }
            }
            node = current.parent()
        }
        return []
    }

    private static func isImportant(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("deadline")
            || lower.contains("last day")
            || lower.contains("exam")
            || lower.contains("important")
    }

    private static func normalizedCalendarDay(from date: Date) -> Date {
        let components = pacificCalendar.dateComponents([.year, .month, .day], from: date)
        return buildCalendarDay(year: components.year, month: components.month, day: components.day) ?? date
    }

    private static func normalizedCalendarDay(fromISO8601 rawDate: String) -> Date? {
        let prefix = String(rawDate.prefix(10))
        let parts = prefix.split(separator: "-")
        guard
            parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2])
        else {
            return nil
        }
        return buildCalendarDay(year: year, month: month, day: day)
    }

    private static func buildCalendarDay(year: Int?, month: Int?, day: Int?) -> Date? {
        guard let year, let month, let day else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        // Midday avoids DST/offset edge cases while preserving the intended local calendar day.
        components.hour = 12
        return pacificCalendar.date(from: components)
    }

    private static var pacificCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Vancouver") ?? .current
        return calendar
    }
}
