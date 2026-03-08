//
//  UpassControlTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-25.
//

import UIKit

class UpassControlTableViewCell: UITableViewCell {
    @IBOutlet var reminderSwitch: UISwitch!
    @IBOutlet var advanceTextLabel: UILabel!
    @IBOutlet var advanceStepper: UIStepper!
    @IBOutlet var calendarView: UIView!
    @IBOutlet var setupBtn: UIButton!
    @IBOutlet var calendarIpadWrapper: UIView!

    static var nib: String {
        return Constants.upassViewIdentifier
    }

    var tableViewDelegate: UpassTableViewControllerProtocol?

    @IBOutlet var switchWrapper: UIView!
    @IBOutlet var stepperWrapper: UIView!
    @IBOutlet var renewBtn: UIButton!
    @IBOutlet var timePicker: UISegmentedControl!

    private let generatorNotice = UINotificationFeedbackGenerator()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)
    private lazy var upassCalendarView: UICalendarView = {
        let view = UICalendarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.calendar = pacificCalendar
        view.locale = Locale(identifier: "en_CA")
        view.timeZone = pacificCalendar.timeZone
        view.fontDesign = .rounded
        view.tintColor = .link
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    var isReminderOn: Bool = ReminderStateStore.hasPendingUpassReminder()
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        // do not call setupCalendar here
    }

    func setupUI() {
        setupBtn.layer.cornerRadius = 8
        switchWrapper.layer.cornerRadius = 8
        calendarIpadWrapper.layer.cornerRadius = 8
        stepperWrapper.layer.cornerRadius = 8
        renewBtn.layer.cornerRadius = 8
        calendarView.layer.cornerRadius = 8
        calendarView.clipsToBounds = true
        advanceStepper.value = 15
        advanceStepper.minimumValue = 1
        advanceStepper.maximumValue = 28
        advanceStepper.stepValue = 1
        advanceStepper.alpha = isReminderOn ? 1 : 0.4

        advanceTextLabel.textColor = isReminderOn ? .label : .quaternaryLabel
        renewBtn.titleLabel?.alpha = isReminderOn ? 1 : 0.7
        setupBtn.titleLabel?.alpha = isReminderOn ? 1 : 0.7
        setupBtn.backgroundColor = isReminderOn ? #colorLiteral(red: 0, green: 0.3568627451, blue: 0.7450980392, alpha: 1) : .quaternaryLabel
        renewBtn.backgroundColor = isReminderOn ? #colorLiteral(red: 0, green: 0.3568627451, blue: 0.7450980392, alpha: 1) : .quaternaryLabel
        timePicker.alpha = isReminderOn ? 1 : 0.7
        timePicker.isEnabled = isReminderOn
        renewBtn.isEnabled = isReminderOn
        setupBtn.isEnabled = isReminderOn
        advanceStepper.isUserInteractionEnabled = isReminderOn
        reminderSwitch.isOn = isReminderOn

        if
            let component = ReminderStateStore.upassReminderComponents(),
            ReminderStateStore.hasPendingUpassReminder(),
            let day = component.day,
            let hours = component.hour
        {
            timePicker.selectedSegmentIndex = hoursToIndex(hours: hours)
            advanceStepper.value = Double(day)
            advanceTextLabel.text = "\(dateStringFormatter(date: day)) Every Month"
        } else {
            timePicker.selectedSegmentIndex = 0
            advanceStepper.value = 15
            advanceTextLabel.text = "\(dateStringFormatter(date: 15)) Every Month"
        }

        embedCalendarViewIfNeeded()
    }

    @IBAction func didPickTime(_ sender: Any) {
        generatorImpact.impactOccurred()
    }

    func setupCalendar() {
        let today = Date()
        upassCalendarView.availableDateRange = DateInterval(start: startDate(), end: endDate())
        upassCalendarView.setVisibleDateComponents(
            pacificCalendar.dateComponents([.year, .month, .day], from: today),
            animated: false
        )
        upassCalendarView.isUserInteractionEnabled = false
        upassCalendarView.alpha = isReminderOn ? 1 : 0.5
        calendarView.alpha = isReminderOn ? 1 : 0.7
    }

    private func embedCalendarViewIfNeeded() {
        guard upassCalendarView.superview == nil else {
            return
        }
        calendarView.addSubview(upassCalendarView)
        NSLayoutConstraint.activate([
            upassCalendarView.topAnchor.constraint(equalTo: calendarView.topAnchor),
            upassCalendarView.leadingAnchor.constraint(equalTo: calendarView.leadingAnchor),
            upassCalendarView.trailingAnchor.constraint(equalTo: calendarView.trailingAnchor),
            upassCalendarView.bottomAnchor.constraint(equalTo: calendarView.bottomAnchor)
        ])
    }

    @IBAction func showPushInfoView(_ sender: Any) {
        tableViewDelegate?.showLegal()
    }

    @IBAction func didChangeStepper(_ sender: Any) {
        generatorImpact.impactOccurred()
        let num = Int(advanceStepper.value)
        advanceTextLabel.text = "\(dateStringFormatter(date: num)) Every Month"
    }

    private func dateStringFormatter(date: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        if let str = formatter.string(from: NSNumber(integerLiteral: date)) {
            return str
        }

        return ""
    }

    @IBAction func didSwitch(_ sender: Any) {
        tableViewDelegate?.checkNotificationAuthorization { isAuthorized in
            guard isAuthorized else {
                self.reminderSwitch.isOn = false
                self.tableViewDelegate?.showAlert()
                return
            }
            // try to turn off
            if !self.reminderSwitch.isOn {
                self.tableViewDelegate?.removeNotification(callback: { shouldOFF in
                    DispatchQueue.main.async {
                        guard shouldOFF else {
                            self.reminderSwitch.isOn = true
                            return
                        }
                        self.isReminderOn = ReminderStateStore.hasPendingUpassReminder()
                        self.generatorImpact.impactOccurred()
                        self.setupUI()
                        self.setupCalendar()
                    }
                })
            } else {
                self.isReminderOn = true
                self.generatorImpact.impactOccurred()
                self.setupUI()
                self.setupCalendar()
            }
        }
    }

    @IBAction func showRenewPage(_ sender: Any) {
        tableViewDelegate?.showRenew()
    }

    @IBAction func showRenewLegal(_ sender: Any) {
        tableViewDelegate?.showPrivacy()
    }

    @IBAction func didSetupReminder(_ sender: Any) {
        var component = DateComponents()
        component.timeZone = .current
        component.minute = 0
        component.hour = convertHours(picker: timePicker.selectedSegmentIndex)
        component.day = Int(advanceStepper.value)
        tableViewDelegate?.setupNotification(forDay: component)
    }

    private func convertHours(picker: Int) -> Int {
        // 9
        // 9 + 3 = 12
        // 9 + 6 = 15
        // 9 + 9 = 18
        // 9 + 12 = 21
        return 9 + picker * 3
    }

    private func hoursToIndex(hours: Int) -> Int {
        return (hours - 9) / 3
    }

    func startDate() -> Date {
        let today = Date()
        return pacificCalendar.date(byAdding: DateComponents(month: -1, day: -1), to: today)!
    }

    func endDate() -> Date {
        let today = Date()
        return pacificCalendar.date(byAdding: DateComponents(month: 1, day: -1), to: today)!
    }

    private var pacificCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Vancouver") ?? .current
        return calendar
    }
}
