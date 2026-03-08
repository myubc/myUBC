//
//  CheckoutTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-02-13.
//

import UIKit

@MainActor
class CheckoutTableViewController: UITableViewController, CheckoutProtocol {
    var isGrantedNotificationAccess: Bool = false
    var isTimerInProgress: Bool {
        return ReminderStateStore.hasPendingChargerTimer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    func setupTableView() {
        tableView.register(UINib(nibName: Constants.chargerCheckoutNib_viewCell, bundle: nil), forCellReuseIdentifier: Constants.chargerCheckout_viewCell)

        tableView.register(UINib(nibName: Constants.chargerCheckoutNib_timerCell, bundle: nil), forCellReuseIdentifier: Constants.chargerCheckout_timerCell)

        tableView.register(UINib(nibName: Constants.countdownCellNib, bundle: nil), forCellReuseIdentifier: Constants.countdownCell)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
    }

    func accessCheck(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge],
            completionHandler: { granted, _ in
                Task { @MainActor in
                    self.isGrantedNotificationAccess = granted
                    completion()
                }
            }
        )
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: Constants.chargerCheckout_viewCell, for: indexPath) as? CheckoutTableViewCell {
                cell.timerProtocol = self
                return cell
            }
        } else if indexPath.row == 1 {
            if isTimerInProgress { return getCountdownCell(at: indexPath) }
            return getTimerSetupCell(at: indexPath)
        }
        return UITableViewCell()
    }

    private func getCountdownCell(at indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Constants.countdownCell) as? TimerTableViewCell {
            cell.timerProtocol = self
            cell.stopBtn.addTarget(self, action: #selector(stopTimer), for: .touchUpInside)
            return cell
        }
        return UITableViewCell()
    }

    private func getTimerSetupCell(at indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Constants.chargerCheckout_timerCell, for: indexPath) as? CheckoutTimerTableViewCell {
            cell.timerProtocol = self
            cell.legalPushBtn.addTarget(self, action: #selector(showLegalPage), for: .touchUpInside)
            cell.legalTermsBtn.addTarget(self, action: #selector(showTerms), for: .touchUpInside)
            cell.legalLoan.addTarget(self, action: #selector(showLoanInfo), for: .touchUpInside)
            return cell
        }
        return UITableViewCell()
    }

    @objc func showLegalPage() {
        present(AppScreenFactory.makeLegal(caseIndex: 0), animated: true)
    }

    @objc func showTerms() {
        present(AppScreenFactory.makeLegal(caseIndex: 1), animated: true)
    }

    @objc func showLoanInfo() {
        present(AppScreenFactory.makeLegal(caseIndex: 2), animated: true)
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */

    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */

    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */

    func startTimer(timeInterval: Double) {
        guard isGrantedNotificationAccess else {
            return
        }

        // Set the content of the notification
        let content = UNMutableNotificationContent()
        content.title = "Return Your Charger"
        // content.subtitle = ""
        content.body = "Overdue fines of $1 per hour may apply. Confirm current lending terms with UBC Library staff."
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = Constants.notification_timer_category
        // Set the trigger of the notification -- here a timer.
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        // Set the request for the notification from the above
        let request = UNNotificationRequest(
            identifier: Constants.notification_timer_identify,
            content: content,
            trigger: trigger
        )

        // Setup buttons
        let action = UNNotificationAction(identifier: Constants.notification_timer_action, title: "Snooze for 5 mins", options: [])
        let categories = UNNotificationCategory(identifier: "timer.snooze", actions: [action], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([categories])

        // Add the notification to the currnet notification center
        UNUserNotificationCenter.current().add(
            request, withCompletionHandler: { _ in
                Task { @MainActor in
                    ReminderStateStore.setChargerTimer(targetDate: Date().advanced(by: timeInterval))
                    self.updateTable()
                }
            }
        )
    }

    func showAlert() {
        let alert = UIAlertController(
            title: "Notifications Disabled",
            message: "Enable notifications for myUBC in Settings to receive charger reminders.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func stopTimer() {
        let alert = UIAlertController(title: "Stop Reminder", message: "Are you sure you want to stop this charger reminder?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Stop Reminder", style: .destructive, handler: { _ in
            ReminderStateStore.clearChargerTimer()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Constants.notification_timer_identify])
            self.updateTable()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func updateTable() {
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .bottom)
            self.tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .bottom)
            self.tableView.endUpdates()
        }
    }

    func showLoanPolicy() {
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = .ubc(url: Constants.loanPolicyURL)
        present(webView, animated: true, completion: nil)
    }
}

@MainActor
protocol CheckoutProtocol: AnyObject {
    var isGrantedNotificationAccess: Bool { get set }
    func accessCheck(completion: @escaping () -> Void)
    func startTimer(timeInterval: Double)
    func showAlert()
    func stopTimer()
    func updateTable()
    func showLoanPolicy()
}
