//
//  CalendarSource.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

enum CalendarSource {
    static let deadLink = URL(string: "https://vancouver.calendar.ubc.ca/dates-and-deadlines")!

    static func sourceURL(for visibleMonth: Date) -> URL {
        let startYear = academicYearStartYear(for: visibleMonth)
        let endYearTwoDigits = (startYear + 1) % 100
        let academicYearToken = "\(startYear)\(String(format: "%02d", endYearTwoDigits))"
        let link = "https://vancouver.calendar.ubc.ca/academic-year-\(academicYearToken)/all-months"
        return URL(string: link) ?? deadLink
    }

    static func isMonthInNextAcademicYear(_ visibleMonth: Date, referenceDate: Date = Date()) -> Bool {
        academicYearStartYear(for: visibleMonth) > academicYearStartYear(for: referenceDate)
    }

    private static func academicYearStartYear(for visibleMonth: Date) -> Int {
        let year = pacificCalendar.component(.year, from: visibleMonth)
        let month = pacificCalendar.component(.month, from: visibleMonth)
        return month >= 9 ? year : year - 1
    }

    private static var pacificCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Vancouver") ?? .current
        return calendar
    }
}
