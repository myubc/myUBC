//
//  CalendarTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2021-01-31.
//

import UIKit

@MainActor
class CalendarTableViewController: UITableViewController, AppContainerInjectable {
    private let generatorNotice = UINotificationFeedbackGenerator()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)
    private let warningBannerTag = 551_204
    private let warningBannerPadding: CGFloat = 16

    var container: AppContainer?
    private var viewModel: CalendarViewModel?
    private let screenModel = CalendarScreenModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        if let container = container {
            viewModel = CalendarViewModel(service: container.calendarService)
        }
        setupNavigation()
        setupCalendar()
        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
    }

    func setupNavigation() {
        let close = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(dismissView),
            accessibilityLabel: "Close calendar"
        )
        navigationItem.setRightBarButton(close, animated: true)

        let info = UIBarButtonItem.appNavIcon(
            systemName: "info.circle",
            target: self,
            action: #selector(showInfo),
            accessibilityLabel: "Calendar details"
        )
        navigationItem.setLeftBarButton(info, animated: true)
        navigationItem.largeTitleDisplayMode = .never
    }

    func setupCalendar(showLoading: Bool = true) {
        if !showLoading {
            screenModel.startLoading()
            refreshDetailSections(animated: true)
        }

        tableView.isUserInteractionEnabled = showLoading ? false : true
        let spinner: UIView?
        if showLoading {
            let effect = (traitCollection.userInterfaceStyle == .dark) ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
            spinner = UIViewController.displaySpinner(onView: view, effect: effect)
        } else {
            spinner = nil
        }
        Task {
            guard let viewModel else { return }
            let result = await viewModel.load(visibleMonth: screenModel.currentMonth)
            await MainActor.run {
                if let spinner {
                    UIViewController.removeSpinner(spinner: spinner)
                }
                switch result {
                case .success:
                    self.screenModel.apply(events: viewModel.events)
                    if let warningMessage = self.warningBannerMessage(for: viewModel) {
                        self.showCalendarWarningBanner(message: warningMessage)
                    } else {
                        self.hideCalendarWarningBanner()
                    }
                    self.setTableFooterStatusMessage(CacheBanner.lastUpdatedMessage(from: viewModel.lastUpdated))
                    self.tableView.isUserInteractionEnabled = true
                    self.refreshDetailSections(animated: true)
                    self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
                case let .failure(error):
                    self.screenModel.clearEvents()
                    self.hideCalendarWarningBanner()
                    self.tableView.isUserInteractionEnabled = true
                    self.presentError(error)
                }
            }
        }
    }

    func showSource() {
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = .ubc(url: CalendarSource.sourceURL(for: screenModel.currentMonth).absoluteString)
        present(webView, animated: true, completion: {
            self.generatorNotice.notificationOccurred(.success)
        })
    }

    func showDeadLink() {
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = .ubc(url: CalendarSource.deadLink.absoluteString)
        present(webView, animated: true, completion: nil)
    }

    @objc func showInfo() {
        let alert = UIAlertController(
            title: NSLocalizedString("alert.details.title", comment: ""),
            message: NSLocalizedString("calendar.details", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("alert.ok", comment: ""), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func dismissView() {
        generatorImpact.impactOccurred()
        dismiss(animated: true, completion: nil)
    }

    func getCurrentMonthIndex() -> Int {
        screenModel.monthIndex()
    }
}

private extension CalendarTableViewController {
    func warningBannerMessage(for viewModel: CalendarViewModel) -> String? {
        if viewModel.events.isEmpty {
            if CalendarSource.isMonthInNextAcademicYear(screenModel.currentMonth) {
                return "UBC has not published dates for this month yet."
            }
            return "Academic dates for this month are currently unavailable."
        }
        return nil
    }

    func showCalendarWarningBanner(message: String) {
        hideCalendarWarningBanner()

        let banner = StatusBannerView()
        banner.tag = warningBannerTag
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.isUserInteractionEnabled = false
        banner.apply(message: message, style: .stale)
        view.addSubview(banner)

        let bannerWidth = view.bounds.width - 24
        let bannerHeight = banner.preferredHeight(forWidth: bannerWidth)
        let constraints = [
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            banner.heightAnchor.constraint(equalToConstant: bannerHeight)
        ]
        NSLayoutConstraint.activate(constraints)

        let insetTop = bannerHeight + warningBannerPadding
        tableView.contentInset.top = insetTop
        tableView.verticalScrollIndicatorInsets.top = insetTop
    }

    func hideCalendarWarningBanner() {
        view.viewWithTag(warningBannerTag)?.removeFromSuperview()
        tableView.contentInset.top = 0
        tableView.verticalScrollIndicatorInsets.top = 0
    }
}

@MainActor
protocol CalendarProtocols {
    func showSourcePopUp()
    func showDeadLink()
}

extension CalendarTableViewController {
    private func refreshDetailSections(animated: Bool = false) {
        let updates = {
            if self.tableView.numberOfSections >= 3 {
                self.tableView.reloadSections(IndexSet(integersIn: 1 ... 2), with: .none)
            } else {
                self.tableView.reloadData()
            }
            self.tableView.layoutIfNeeded()
        }

        if animated {
            UIView.transition(
                with: tableView,
                duration: 0.2,
                options: [.transitionCrossDissolve, .allowAnimatedContent]
            ) {
                updates()
            }
        } else {
            UIView.performWithoutAnimation {
                updates()
            }
        }
    }

    func reloadTableContent() {
        let allButFirst = (tableView.indexPathsForVisibleRows ?? []).filter { $0.section != 0 && $0.row != 0 }
        tableView.reloadRows(at: allButFirst, with: .bottom)
    }

    func setupTable() {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag
        tableView.insetsContentViewsToSafeArea = true
        tableView.estimatedRowHeight = 410
        tableView.sectionHeaderTopPadding = 0

        tableView.register(UINib(nibName: CalendarMainTableViewCell.nib, bundle: nil), forCellReuseIdentifier: CalendarMainTableViewCell.nib)
        tableView.register(UINib(nibName: CalendarFooterTableViewCell.nib, bundle: nil), forCellReuseIdentifier: CalendarFooterTableViewCell.nib)
        tableView.register(UINib(nibName: CalendarContentTableViewCell.nib, bundle: nil), forCellReuseIdentifier: CalendarContentTableViewCell.nib)
        tableView.register(UINib(nibName: CalendarErrorTableViewCell.nib, bundle: nil), forCellReuseIdentifier: CalendarErrorTableViewCell.nib)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        screenModel.sectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        screenModel.rowCount(in: section)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if screenModel.events != nil || screenModel.isLoading {
            if indexPath.section == 0 {
                // first
                return dequeueMainCell()
            } else if indexPath.section == 1 {
                // middle
                return dequeueContent(tableView: tableView, indexPath: indexPath)
            } else {
                return dequeueBottoView()
            }
        } else {
            return dequeueErrorView()
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func dequeueMainCell() -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarMainTableViewCell.nib) as? CalendarMainTableViewCell else {
            return UITableViewCell()
        }
        cell.clipsToBounds = false
        cell.layer.masksToBounds = false
        cell.delegate = self
        cell.configure(
            days: screenModel.dayModels,
            visibleMonth: screenModel.currentMonth,
            selectedDate: screenModel.currentDay,
            availableDateRange: DateInterval(start: startDate(), end: endDate())
        )
        cell.selectionStyle = .none
        return cell
    }

    func dequeueBottoView() -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarFooterTableViewCell.nib) as? CalendarFooterTableViewCell else {
            return UITableViewCell()
        }
        cell.parent = self
        cell.selectionStyle = .none
        return cell
    }

    func dequeueContent(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 1 else {
            return UITableViewCell()
        }

        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: CalendarContentTableViewCell.nib) as? CalendarContentTableViewCell,
            screenModel.events != nil || screenModel.isLoading
        else {
            return UITableViewCell()
        }

        if screenModel.isLoading {
            cell.setLoading()
        } else if let event = screenModel.selectedEvents[safe: indexPath.row] {
            cell.setupModel(model: event)
        } else {
            cell.setNoEvent()
        }

        cell.isFirst = indexPath.row == 0
        cell.isLast = indexPath.row == tableView.numberOfRows(inSection: 1) - 1
        cell.setupUI()
        cell.setupCorners()
        cell.selectionStyle = .none
        return cell
    }

    func dequeueErrorView() -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarErrorTableViewCell.nib) as? CalendarErrorTableViewCell else {
            return UITableViewCell()
        }
        cell.setup()
        cell.calendarProtocol = self
        cell.selectionStyle = .none
        return cell
    }

    func todayIndexInEvent() -> Int? {
        screenModel.selectedDayIndex()
    }

    private func dateToString(date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        // df.locale = Locale(identifier: "en_CA")
        // df.timeZone = TimeZone.init(abbreviation: "PST")
        df.timeZone = TimeZone(abbreviation: "UTC")
        return df.string(from: date)
    }
}

extension CalendarTableViewController {
    func startDate() -> Date {
        let today = Date()
        let year = pacificCalendar.component(.year, from: today)
        let month = pacificCalendar.component(.month, from: today)
        let academicYearStart = month >= 9 ? year : year - 1
        return pacificCalendar.date(from: DateComponents(year: academicYearStart, month: 9, day: 1, hour: 12)) ?? today
    }

    func endDate() -> Date {
        screenModel.endDate()
    }
}

extension CalendarTableViewController: CalendarMainTableViewCellDelegate {
    func calendarCell(_ cell: CalendarMainTableViewCell, didSelect date: Date) {
        if !screenModel.selectDay(date) {
            return
        }

        UIView.transition(
            with: tableView,
            duration: 0.2,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
            self.tableView.layoutIfNeeded()
        }

        generatorImpact.impactOccurred()
    }

    func calendarCell(_ cell: CalendarMainTableViewCell, didChangeVisibleMonth date: Date) {
        if screenModel.shouldReloadForScrolledMonth(date) {
            screenModel.setCurrentMonth(date)
            if !pacificCalendar.isDate(screenModel.currentDay, equalTo: date, toGranularity: .month) {
                screenModel.setCurrentDay(date)
            }
            setupCalendar(showLoading: false)
        }
    }
}

private extension CalendarTableViewController {
    var pacificCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Vancouver") ?? .current
        return calendar
    }
}

extension CalendarTableViewController: CalendarProtocols {
    func showSourcePopUp() {
        showSource()
    }
}
