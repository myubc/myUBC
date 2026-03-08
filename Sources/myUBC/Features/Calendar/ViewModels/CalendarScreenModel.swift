//
//  CalendarScreenModel.swift
//  myUBC
//
//  Created by myUBC on 2025-07-07.
//

import Foundation

@MainActor
final class CalendarScreenModel {
    private(set) var events: [CampusCalendarEvent]?
    private(set) var currentMonth: Date
    private(set) var currentDay: Date
    private(set) var isLoading = false

    init(currentMonth: Date = .init(), currentDay: Date = .init()) {
        self.currentMonth = Self.startOfMonth(for: currentMonth)
        self.currentDay = Self.normalizedDay(for: currentDay)
    }

    var dayModels: [CampusCalendarEvent] {
        events ?? []
    }

    var selectedEvents: [CampusEventDetail] {
        guard !isLoading else {
            return []
        }
        guard
            let index = selectedDayIndex(),
            let events,
            index < events.count
        else {
            return []
        }
        return events[index].events
    }

    var sectionCount: Int {
        events == nil && !isLoading ? 1 : 3
    }

    func apply(events: [CampusCalendarEvent]) {
        self.events = events
        isLoading = false
    }

    func clearEvents() {
        events = nil
        isLoading = false
    }

    func startLoading() {
        isLoading = true
    }

    func rowCount(in section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            if isLoading {
                return 1
            }
            let count = selectedEvents.count
            return count == 0 ? 1 : count
        case 2:
            return (events == nil && !isLoading) ? 0 : 1
        default:
            return 1
        }
    }

    func monthIndex() -> Int {
        Self.pacificCalendar.component(.month, from: currentMonth)
    }

    func setCurrentMonth(_ date: Date) {
        currentMonth = Self.startOfMonth(for: date)
    }

    func setCurrentDay(_ date: Date) {
        currentDay = Self.normalizedDay(for: date)
    }

    func selectDay(_ date: Date) -> Bool {
        let normalizedDate = Self.normalizedDay(for: date)
        guard !Self.isSameUTCDay(lhs: currentDay, rhs: normalizedDate) else {
            return false
        }
        currentDay = normalizedDate
        return true
    }

    func shouldReloadForScrolledMonth(_ date: Date) -> Bool {
        let normalizedDate = Self.startOfMonth(for: date)
        return !Self.pacificCalendar.isDate(currentMonth, equalTo: normalizedDate, toGranularity: .month)
    }

    func selectedDayIndex() -> Int? {
        guard let events else { return nil }
        return events.firstIndex { event in
            Self.isSameUTCDay(lhs: currentDay, rhs: event.date)
        }
    }

    func endDate(referenceDate: Date = Date()) -> Date {
        var monthForward = 1
        let normalizedReferenceDate = Self.normalizedDay(for: referenceDate)
        if let month = Self.pacificCalendar.dateComponents([.month], from: normalizedReferenceDate).month {
            if month > 8 {
                monthForward = 12 - (month - 8)
            } else {
                monthForward = 8 - month
            }

            if let endMonth = Self.pacificCalendar.date(byAdding: DateComponents(month: monthForward, day: -1), to: normalizedReferenceDate) {
                return Self.endOfMonth(for: endMonth)
            }
        }
        if let fallback = Self.pacificCalendar.date(byAdding: DateComponents(month: 1, day: -1), to: normalizedReferenceDate) {
            return Self.endOfMonth(for: fallback)
        }
        return Self.endOfMonth(for: normalizedReferenceDate)
    }

    private static func isSameUTCDay(lhs: Date, rhs: Date) -> Bool {
        pacificCalendar.isDate(lhs, inSameDayAs: rhs)
    }

    private static func normalizedDay(for date: Date) -> Date {
        let components = pacificCalendar.dateComponents([.year, .month, .day], from: date)
        return pacificCalendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: 12)) ?? date
    }

    private static func startOfMonth(for date: Date) -> Date {
        let components = pacificCalendar.dateComponents([.year, .month], from: date)
        return pacificCalendar.date(from: DateComponents(year: components.year, month: components.month, day: 1, hour: 12)) ?? normalizedDay(for: date)
    }

    private static func endOfMonth(for date: Date) -> Date {
        let start = startOfMonth(for: date)
        if
            let nextMonth = pacificCalendar.date(byAdding: DateComponents(month: 1), to: start),
            let end = pacificCalendar.date(byAdding: DateComponents(day: -1), to: nextMonth)
        {
            return normalizedDay(for: end)
        }
        return normalizedDay(for: date)
    }

    private static var pacificCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Vancouver") ?? .current
        return calendar
    }
}
