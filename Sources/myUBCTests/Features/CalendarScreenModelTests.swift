@testable import myUBC
import XCTest

@MainActor
final class CalendarScreenModelTests: XCTestCase {
    func testSelectedEventsFollowCurrentDay() {
        let date = makeDate(year: 2026, month: 3, day: 7)
        let nextDay = makeDate(year: 2026, month: 3, day: 8)
        let model = CalendarScreenModel(currentMonth: date, currentDay: date)
        model.apply(events: [
            CampusCalendarEvent(date: date, events: [CampusEventDetail(isImportant: true, eventDescription: "Midterm")]),
            CampusCalendarEvent(date: nextDay, events: [CampusEventDetail(isImportant: false, eventDescription: "Break")])
        ])

        XCTAssertEqual(model.selectedEvents.first?.eventDescription, "Midterm")
        XCTAssertEqual(model.rowCount(in: 1), 1)

        XCTAssertTrue(model.selectDay(nextDay))
        XCTAssertEqual(model.selectedEvents.first?.eventDescription, "Break")
    }

    func testSectionCountFallsBackToErrorStateWithoutEvents() {
        let model = CalendarScreenModel()

        XCTAssertEqual(model.sectionCount, 1)
        XCTAssertEqual(model.rowCount(in: 0), 1)
        XCTAssertEqual(model.rowCount(in: 2), 0)
    }

    func testShouldReloadForScrolledMonthOnlyWhenMonthChanges() {
        let march = makeDate(year: 2026, month: 3, day: 7)
        let marchLater = makeDate(year: 2026, month: 3, day: 20)
        let april = makeDate(year: 2026, month: 4, day: 1)
        let model = CalendarScreenModel(currentMonth: march, currentDay: march)

        XCTAssertFalse(model.shouldReloadForScrolledMonth(marchLater))
        XCTAssertTrue(model.shouldReloadForScrolledMonth(april))
    }

    func testPacificCalendarDayDoesNotShiftForUtcTimestamp() {
        let pacificMorning = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(identifier: "UTC"),
            year: 2026,
            month: 3,
            day: 8,
            hour: 20,
            minute: 30
        ).date ?? Date()
        let eventDate = makeDate(year: 2026, month: 3, day: 8)

        let model = CalendarScreenModel(currentMonth: pacificMorning, currentDay: pacificMorning)
        model.apply(events: [
            CampusCalendarEvent(date: eventDate, events: [CampusEventDetail(isImportant: true, eventDescription: "Deadline")])
        ])

        XCTAssertEqual(model.selectedEvents.first?.eventDescription, "Deadline")
        XCTAssertFalse(model.selectDay(pacificMorning))
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Vancouver") ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }
}
