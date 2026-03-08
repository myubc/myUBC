//
//  RemindersTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-03-28.
//

import UIKit

@MainActor
class RemindersTableViewController: UITableViewController, RemindersTableViewControllerProtocol {
    var doneBlock: (() -> Void)?
    var showUpassBlock: (() -> Void)?
    var navigateCollection: (() -> Void)?

    weak var delegate: LandingViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupNav()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.globalHeader?.badgeCheck()
    }

    func setupNav() {
        let close = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(dismissView),
            accessibilityLabel: "Close reminders"
        )
        navigationItem.setRightBarButton(close, animated: true)
    }

    func setupTable() {
        tableView.separatorStyle = .none
        tableView.register(
            UINib(nibName: Constants.countdownCellNib, bundle: nil),
            forCellReuseIdentifier: Constants.countdownCell
        )
        tableView.register(
            UINib(nibName: ReminderUpassTableViewCell.nib, bundle: nil),
            forCellReuseIdentifier: ReminderUpassTableViewCell.nib
        )
    }

    @objc func stopTimer() {
        let alert = UIAlertController(
            title: "Stop Timer",
            message: "Are you sure you want to stop the timer now?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            ReminderStateStore.clearChargerTimer()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Constants.notification_timer_identify])
            self.tableView.reloadData()
            self.animateTable()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func dismissView() {
        dismiss(animated: true, completion: {
            self.doneBlock?()
        })
    }

    @objc func showUpass() {
        navigateCollection?()
        dismiss(animated: true, completion: {
            self.doneBlock?()
            self.showUpassBlock?()
        })
    }

    private func animateTable() {
        tableView.isUserInteractionEnabled = false
        tableView.showsVerticalScrollIndicator = false
        // Animate Table Cells
        let cells = tableView.visibleCells
        let tableHeight: CGFloat = tableView.bounds.size.height
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransform(
                translationX: 0,
                y: tableHeight
            )
        }
        var index = 0
        for a in cells {
            let cell: UITableViewCell = a as UITableViewCell
            UIView.animate(
                withDuration: 1,
                delay: 0.05 * Double(index),
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                options: [],
                animations: {
                    cell.transform = CGAffineTransform(translationX: 0, y: 0)
                },
                completion: { _ in
                    self.tableView.isUserInteractionEnabled = true
                    self.tableView.showsVerticalScrollIndicator = true
                }
            )
            index += 1
        }
    }

    func countdownFinished() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.animateTable()
        }
    }
}

@MainActor
protocol RemindersTableViewControllerProtocol: AnyObject {
    func countdownFinished()
}

extension RemindersTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 1 // upass cell always present
        if ReminderStateStore.hasPendingChargerTimer() {
            count += 1
        }
        return count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    )
        -> UITableViewCell
    {
        let timerOn = ReminderStateStore.hasPendingChargerTimer()
        // compute logical row mapping
        var row = indexPath.row
        if timerOn {
            if row == 0 {
                return getCountdown(forIndexpath: indexPath)
            }
            row -= 1
        }

        // now row == 0 -> upass cell
        if row == 0 {
            return getUpassCell(forIndexpath: indexPath)
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func getUpassCell(forIndexpath indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReminderUpassTableViewCell.nib) as? ReminderUpassTableViewCell else {
            return UITableViewCell()
        }
        cell.showUpassPage.addTarget(self, action: #selector(showUpass), for: .touchUpInside)
        return cell
    }

    private func getCountdown(forIndexpath indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.countdownCell,
                for: indexPath
            ) as? TimerTableViewCell
        else {
            return UITableViewCell()
        }
        cell.reminderProtocol = self
        cell.stopBtn.addTarget(self, action: #selector(stopTimer), for: .touchUpInside)
        return cell
    }
}
