//
//  NoticeTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-03-12.
//

import UIKit

@MainActor
class NoticeTableViewController: UITableViewController, NotificationProtocol, AppContainerInjectable {
    var container: AppContainer?
    private var viewModel: NoticeViewModel?
    private var screenState = NoticeScreenState()
    private let generatorNotice = UINotificationFeedbackGenerator()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)

    override func viewDidLoad() {
        super.viewDidLoad()
        if let container = container {
            viewModel = NoticeViewModel(service: container.infoService)
        }
        setupNavigation()
        setupTable()
        requestUpdate()
    }

    private func setupNavigation() {
        let refreshButton = UIButton(type: .system)
        refreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshButton.tintColor = .label
        refreshButton.accessibilityLabel = "Refresh bulletin"
        refreshButton.addTarget(self, action: #selector(didTapNavRefresh), for: .touchUpInside)
        let refresh = UIBarButtonItem(customView: refreshButton)
        let close = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(didClose(_:)),
            accessibilityLabel: "Close bulletin"
        )
        navigationItem.setLeftBarButton(refresh, animated: false)
        navigationItem.setRightBarButton(close, animated: false)
    }

    @objc private func didTapNavRefresh() {
        requestUpdateForcingRefresh(true)
    }

    func setupTable() {
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        tableView.register(UINib(nibName: Constants.notificationTableIdentifier, bundle: nil), forCellReuseIdentifier: Constants.notificationTableIdentifier)
        tableView.register(UINib(nibName: Constants.titleTableIdentifier, bundle: nil), forCellReuseIdentifier: Constants.titleTableIdentifier)

        // for screenshots or demos
        /* notifications = [CampusNotification(title: "Vancouver Campus Weather Advisory", time: "Nov, 30 2022 – 5:05 p.m. PDT", content: "In-person, on-campus morning classes starting before 1 p.m. at UBC Vancouver's Point Grey campus are cancelled due to weather conditions. A decision on in-person, on-campus classes starting after 1 p.m. today is pending. An update on those classes will be posted here by 11 a.m. Please note the campus is NOT closed. Essential staff are expected to come to work. Non- essential staff are expected to come to work unless they've spoken with, or received direction from, their manager and made alternative arrangements, ", notificationID: "23234")]
         wasLastUpdateSuccessful = true */
    }

    private func shrink(down: Bool, cell: UITableViewCell) {
        UIView.animate(withDuration: 0.2) {
            if down {
                cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } else {
                cell.transform = .identity
            }
        }
    }

    @IBAction func didNavRefresh(_ sender: Any) {
        didTapNavRefresh()
    }

    @IBAction func didClose(_ sender: Any) {
        generatorImpact.impactOccurred()
        dismiss(animated: true, completion: nil)
    }

    @objc func requestUpdate() {
        performUpdate(forceRefresh: false)
    }

    func requestUpdateForcingRefresh(_ forceRefresh: Bool) {
        performUpdate(forceRefresh: forceRefresh)
    }

    private func performUpdate(forceRefresh: Bool) {
        generatorImpact.impactOccurred()

        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TitleTableViewCell {
            cell.showLoadingView()
        }

        screenState.beginRefresh()

        if tableView.numberOfRows(inSection: 0) > 1 {
            tableView.beginUpdates()
            tableView.deleteRows(
                at: [IndexPath(row: 1, section: 0)],
                with: .automatic
            )
            tableView.endUpdates()
        }
        Task {
            guard let viewModel = viewModel else { return }
            let result = await viewModel.load(forceRefresh: forceRefresh)
            await MainActor.run {
                switch result {
                case .success:
                    self.screenState.applySuccess(
                        notifications: viewModel.notifications,
                        lastUpdated: viewModel.lastUpdated,
                        banner: viewModel.banner
                    )
                    self.setTableFooterStatusMessage(self.screenState.footerMessage)
                    self.hideLoadingIndicator()
                    self.tableView.reloadData()
                    self.animateTable()
                case let .failure(error):
                    self.screenState.applyFailure(lastUpdated: viewModel.lastUpdated, banner: viewModel.banner)
                    self.setTableFooterStatusMessage(self.screenState.footerMessage)
                    self.hideLoadingIndicator()
                    self.tableView.reloadData()
                    self.presentError(error)
                }
            }
        }
    }

    private func hideLoadingIndicator() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TitleTableViewCell else {
            return
        }
        cell.loadingView.stop()
        UIView.animate(withDuration: 0.2) {
            cell.loadingView.isHidden = true
        }
    }

    func showMore(id: String) {
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = .ubc(url: Constants.campusInfoURL + "#" + id)
        present(webView, animated: true, completion: nil)
    }

    private func animateTable() {
        tableView.isUserInteractionEnabled = false

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
                }
            )
            index += 1
        }
    }
}

@MainActor
protocol NotificationProtocol: AnyObject {
    func showMore(id: String)
}

extension NoticeTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        screenState.rowCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: Constants.titleTableIdentifier,
                    for: indexPath
                ) as? TitleTableViewCell
            {
                cell.refreshBtn.addTarget(self, action: #selector(requestUpdate), for: .touchUpInside)
                cell.showError = !screenState.wasLastUpdateSuccessful
                cell.lastUpdatedDate = screenState.lastUpdated
                cell.showsTimestampLabel = screenState.showsTimestampLabel
                cell.warnings = screenState.notifications
                return cell
            }
        }

        if
            let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.notificationTableIdentifier,
                for: indexPath
            ) as? NotificationTableViewCell
        {
            cell.model = screenState.notifications[indexPath.row - 1]
            cell.notificationProtocol = self
            return cell
        }

        // Configure the cell...

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            shrink(down: true, cell: cell)
        }
    }

    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            shrink(down: false, cell: cell)
        }
    }
}
