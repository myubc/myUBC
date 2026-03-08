//
//  CalendarMainTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2021-01-31.
//

import UIKit

@MainActor
protocol CalendarMainTableViewCellDelegate: AnyObject {
    func calendarCell(_ cell: CalendarMainTableViewCell, didSelect date: Date)
    func calendarCell(_ cell: CalendarMainTableViewCell, didChangeVisibleMonth date: Date)
}

@MainActor
final class CalendarMainTableViewCell: UITableViewCell {
    @IBOutlet var calendarContainerView: UIView!
    @IBOutlet var shadowView: UIView!
    @IBOutlet var calendarHeaderExtension: UIView!

    static var nib: String {
        "CalendarMainTableViewCell"
    }

    weak var delegate: CalendarMainTableViewCellDelegate?

    private lazy var selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
    private lazy var calendarView: UICalendarView = {
        let view = UICalendarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.calendar = pacificCalendar
        view.locale = Locale(identifier: "en_CA")
        view.timeZone = pacificCalendar.timeZone
        view.fontDesign = .rounded
        view.tintColor = Self.calendarBlue
        view.wantsDateDecorations = true
        view.selectionBehavior = selectionBehavior
        return view
    }()

    private var dayStyles: [DayKey: DotStyle] = [:]
    private var isApplyingProgrammaticMonthChange = false

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        embedCalendarView()
    }

    func configure(days: [CampusCalendarEvent], visibleMonth: Date, selectedDate: Date, availableDateRange: DateInterval) {
        dayStyles = Dictionary(uniqueKeysWithValues: days.compactMap { day in
            guard let style = DotStyle(events: day.events) else {
                return nil
            }
            return (DayKey(from: day.date, calendar: pacificCalendar), style)
        })

        calendarView.availableDateRange = availableDateRange
        calendarView.reloadDecorations(forDateComponents: dayStyles.keys.map(\.dateComponents), animated: false)

        let visibleDateComponents = makeMonthComponents(from: visibleMonth)
        if !matchesMonth(calendarView.visibleDateComponents, visibleDateComponents) {
            isApplyingProgrammaticMonthChange = true
            calendarView.setVisibleDateComponents(visibleDateComponents, animated: false)
            isApplyingProgrammaticMonthChange = false
        }

        let selectedDateComponents = makeDayComponents(from: selectedDate)
        if selectionBehavior.selectedDate != selectedDateComponents {
            selectionBehavior.setSelected(selectedDateComponents, animated: false)
        }
    }

    private func setupUI() {
        calendarHeaderExtension.isHidden = true
        calendarContainerView.backgroundColor = .secondarySystemBackground
        calendarContainerView.layer.cornerRadius = 8
        calendarContainerView.clipsToBounds = true
        shadowView.layer.masksToBounds = true
        shadowView.layer.cornerRadius = 8
        shadowView.layer.shadowOpacity = 0
    }

    private func embedCalendarView() {
        calendarContainerView.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
        ])
    }

    private func makeDayComponents(from date: Date) -> DateComponents {
        let components = pacificCalendar.dateComponents([.year, .month, .day], from: date)
        var normalized = DateComponents()
        normalized.calendar = pacificCalendar
        normalized.timeZone = pacificCalendar.timeZone
        normalized.year = components.year
        normalized.month = components.month
        normalized.day = components.day
        return normalized
    }

    private func makeMonthComponents(from date: Date) -> DateComponents {
        let components = pacificCalendar.dateComponents([.year, .month], from: date)
        var normalized = DateComponents()
        normalized.calendar = pacificCalendar
        normalized.timeZone = pacificCalendar.timeZone
        normalized.year = components.year
        normalized.month = components.month
        normalized.day = 1
        return normalized
    }

    private func matchesMonth(_ lhs: DateComponents, _ rhs: DateComponents) -> Bool {
        lhs.year == rhs.year && lhs.month == rhs.month
    }

    private var pacificCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Vancouver") ?? .current
        return calendar
    }

    private static let calendarBlue = #colorLiteral(red: 0, green: 0.3558964133, blue: 0.7463451028, alpha: 1)
}

@MainActor
extension CalendarMainTableViewCell: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard
            let dateComponents,
            let date = pacificCalendar.date(from: dateComponents)
        else {
            return
        }
        delegate?.calendarCell(self, didSelect: date)
    }

    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        dateComponents != nil
    }
}

@MainActor
extension CalendarMainTableViewCell: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let style = dayStyles[DayKey(from: dateComponents)] else {
            return nil
        }
        return .customView {
            style.decorationView()
        }
    }

    func calendarView(_ calendarView: UICalendarView, didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents) {
        guard !isApplyingProgrammaticMonthChange else {
            return
        }
        let visible = calendarView.visibleDateComponents
        guard !matchesMonth(previousDateComponents, visible) else {
            return
        }
        guard let date = pacificCalendar.date(from: visible) else {
            return
        }
        delegate?.calendarCell(self, didChangeVisibleMonth: date)
    }
}

@MainActor
private extension CalendarMainTableViewCell {
    struct DayKey: Hashable {
        let year: Int
        let month: Int
        let day: Int

        init(from date: Date, calendar: Calendar) {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            year = components.year ?? 0
            month = components.month ?? 0
            day = components.day ?? 0
        }

        init(from dateComponents: DateComponents) {
            year = dateComponents.year ?? 0
            month = dateComponents.month ?? 0
            day = dateComponents.day ?? 0
        }

        var dateComponents: DateComponents {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            return components
        }
    }

    enum DotStyle {
        case regular
        case important
        case mixed

        init?(events: [CampusEventDetail]) {
            guard !events.isEmpty else {
                return nil
            }
            let hasImportant = events.contains(where: \.isImportant)
            let hasRegular = events.contains(where: { !$0.isImportant })

            switch (hasImportant, hasRegular) {
            case (true, true):
                self = .mixed
            case (true, false):
                self = .important
            case (false, true):
                self = .regular
            case (false, false):
                return nil
            }
        }

        private static let regularColor = #colorLiteral(red: 0, green: 0.6606139541, blue: 0.9780436158, alpha: 1)
        private static let importantColor = #colorLiteral(red: 0.8510990296, green: 0.226861841, blue: 0.1955896148, alpha: 1)

        @MainActor
        func decorationView() -> UIView {
            switch self {
            case .regular:
                return makeSingleDot(color: Self.regularColor)
            case .important:
                return makeSingleDot(color: Self.importantColor)
            case .mixed:
                return makeDualDot()
            }
        }

        @MainActor private func makeSingleDot(color: UIColor) -> UIView {
            let dot = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
            dot.backgroundColor = color
            dot.layer.cornerRadius = 3
            return dot
        }

        @MainActor private func makeDualDot() -> UIView {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 6))
            let blueDot = makeSingleDot(color: Self.regularColor)
            blueDot.frame.origin = CGPoint(x: 0, y: 0)
            let redDot = makeSingleDot(color: Self.importantColor)
            redDot.frame.origin = CGPoint(x: 8, y: 0)
            container.addSubview(blueDot)
            container.addSubview(redDot)
            return container
        }
    }
}
