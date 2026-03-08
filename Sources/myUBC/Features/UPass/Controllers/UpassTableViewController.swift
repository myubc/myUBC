//
//  UpassTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-03-25.
//

import UIKit

@MainActor
class UpassTableViewController: UITableViewController, UpassTableViewControllerProtocol {
    private let generatorNotice = UINotificationFeedbackGenerator()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)

    weak var delegate: LandingViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.reload(for: .upass)
    }

    // MARK: - Table view data source

    func setupTable() {
        tableView.register(UINib(nibName: UpassControlTableViewCell.nib, bundle: nil), forCellReuseIdentifier: UpassControlTableViewCell.nib)
        let close = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(dismissView),
            accessibilityLabel: "Close U-Pass"
        )
        navigationItem.setRightBarButton(close, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UpassControlTableViewCell.nib) as? UpassControlTableViewCell else {
            return UITableViewCell()
        }

        cell.tableViewDelegate = self
        cell.setupCalendar()
        return cell
    }

    @objc func dismissView() {
        generatorImpact.impactOccurred()
        dismiss(animated: true, completion: nil)
    }

    func showLegal() {
        let controller = AppScreenFactory.makeLegal(caseIndex: 0)
        present(controller, animated: true)
    }

    func showRenew() {
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = .upassRenewal()
        present(webView, animated: true, completion: nil)
    }

    func showPrivacy() {
        let controller = AppScreenFactory.makeLegal(caseIndex: 3)
        present(controller, animated: true)
    }

    func showAlert() {
        generatorNotice.notificationOccurred(.error)
        let alert = UIAlertController(
            title: "Notifications Disabled",
            message: "Enable notifications for myUBC in Settings to receive renewal reminders.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    private func showAlert(
        withTitle title: String,
        andMessage msg: String,
        withBtnLabel btn: String,
        andAction callback: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btn, style: .cancel, handler: { _ in
            callback()
        }))
        present(alert, animated: true, completion: nil)
    }

    private func dateStringFormatter(date: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        if let str = formatter.string(from: NSNumber(integerLiteral: date)) {
            return str
        }
        return ""
    }

    func setupNotification(forDay dateInfo: DateComponents) {
        ReminderStateStore.setUpassReminder(dateInfo)

        // Set the content of the notification
        let content = UNMutableNotificationContent()
        content.title = "It's Time to Renew Your Upass for This Month"
        content.body = "Click here to renew now."
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = Constants.notification_upass_identifier
        // Set the trigger of the notification -- here a timer.
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: true)

        // Set the request for the notification from the above
        let request = UNNotificationRequest(
            identifier: Constants.notification_upass_identifier,
            content: content,
            trigger: trigger
        )
        if let date = dateInfo.day {
            let str = dateStringFormatter(date: date)

            // Add the notification to the current notification center
            UNUserNotificationCenter.current().add(
                request, withCompletionHandler: { _ in
                    DispatchQueue.main.async {
                        self.generatorNotice.notificationOccurred(.success)
                        self.showAlert(
                            withTitle: "Reminder Scheduled",
                            andMessage: "You are all set. myUBC will remind you on the \(str) of each month.",
                            withBtnLabel: "OK",
                            andAction: {}
                        )
                    }
                }
            )
        }
    }

    func removeNotification(callback: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Turn Off Reminder",
            message: "Are you sure you want to turn off your monthly U-Pass renewal reminders?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Turn Off", style: .destructive, handler: { _ in
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Constants.notification_upass_identifier])
            ReminderStateStore.clearUpassReminder()
            DispatchQueue.main.async {
                callback(true)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            DispatchQueue.main.async {
                callback(false)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}

@MainActor
protocol UpassTableViewControllerProtocol: AnyObject {
    func showLegal()
    func showRenew()
    func showPrivacy()
    func checkNotificationAuthorization(completion: @escaping (Bool) -> Void)
    func showAlert()
    func setupNotification(forDay: DateComponents)
    func removeNotification(callback: @escaping (Bool) -> Void)
}
