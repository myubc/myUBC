//
//  LandingViewController.swift
//  myUBC
//
//  Created by myUBC on 2022-09-07.
//

import UIKit

// swiftlint:disable file_length

@MainActor
class LandingViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, AppContainerInjectable {
    var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    // MARK: Touch Experience

    private let generatorNotice = UINotificationFeedbackGenerator()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)

    var container: AppContainer?
    private var viewModel: LandingViewModel?
    private var statusNoticeMessage: String?
    private var statusNoticeStyle: StatusBannerStyle = .offline

    // MARK: Header Status

    var globalHeader: LandingHeader?
    private var sectionAction: [LandingPageSectionType: () -> Void] = [:]
    private var statusBarShadow: UIView = .init()
    private let gradient = CAGradientLayer()
    lazy var statusBarHeight: CGFloat = {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionCell()
        setupShadow()
        setupTraitChangeObservers()
        loadAllAgents()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkVersion()
        if let routeStore = container?.pendingRouteStore {
            Task { @MainActor in
                await AppRoutePresenter.presentPendingIfNeeded(from: self, store: routeStore)
            }
        }
    }

    func setupCollectionCell() {
        setupNibs()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.delaysContentTouches = false
        collectionView.accessibilityIdentifier = "landing.collection"
        collectionView.backgroundColor = UIColor(named: "LandingBackground")
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
    }

    func setupShadow() {
        statusBarShadow = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: statusBarHeight * 3
        ))
        gradient.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: statusBarHeight * 3
        )
        updateShadowGradientColors()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.shadowRadius = 5
        statusBarShadow.layer.insertSublayer(gradient, at: 0)
        statusBarShadow.isUserInteractionEnabled = false
        view.addSubview(statusBarShadow)
        view.bringSubviewToFront(statusBarShadow)
    }

    private func updateShadowGradientColors() {
        gradient.colors = [
            UIColor.systemGroupedBackground.cgColor,
            UIColor.systemGroupedBackground.withAlphaComponent(0).cgColor
        ]
    }

    private func setupTraitChangeObservers() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.updateShadowGradientColors()
        }
    }

    private func loadAllAgents() {
        guard let hub = container?.dataHub else { return }
        let viewModel = LandingViewModel(dataHub: hub)
        self.viewModel = viewModel

        Task { [weak self] in
            await viewModel.loadSnapshot()
            await MainActor.run {
                LandingPageModel.sections.forEach { self?.reload(for: $0.type) }
            }
        }
    }

    func reload(for section: LandingPageSectionType) {
        DispatchQueue.main.async {
            guard let index = self.sectionIndex(for: section) else { return }
            let set = IndexSet(integer: index)
            self.collectionView.reloadSections(set)
        }
    }

    private func sectionIndex(for type: LandingPageSectionType) -> Int? {
        LandingPageModel.sections.firstIndex { $0.type == type }
    }

    private func sectionType(at index: Int) -> LandingPageSectionType? {
        LandingPageModel.sections[safe: index]?.type
    }

    private func isSectionLoading(_ type: LandingPageSectionType) -> Bool {
        viewModel?.isSectionLoading(type) ?? true
    }

    private func updateGlobalHeaderNotice() {
        globalHeader?.configureStatusMessage(statusNoticeMessage, style: statusNoticeStyle)
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: Navigation

extension LandingViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch sectionType(at: indexPath.section) {
        case .food:
            switch indexPath.row {
            case 0:
                presentFood(withSearchTerm: nil)
            case 1:
                presentFood(withSearchTerm: "Starbucks")
            case 2:
                presentFood(withSearchTerm: "Tim Hortons")
            case 3:
                presentFood(withSearchTerm: "Booster Juice")
            case 4:
                presentFood(withSearchTerm: "Triple Os")
            default:
                presentFood(withSearchTerm: nil)
            }
        case .charger:
            // showCharger
            presentCharger()
        case .calendar:
            presentCalendar()
        case .parking:
            presentParking()
        case .upass:
            presentUpass()
        case .info:
            presentInfo()
        default:
            break
        }
        generatorImpact.impactOccurred()
    }

    private func presentCharger() {
        let controller = AppScreenFactory.makeCharger(
            container: container,
            preloadedLibraryModel: viewModel?.libraryModel ?? LibraryModel(),
            preloadedLastUpdated: viewModel?.libraryLastUpdated,
            presentationDelegate: self
        )
        present(controller, animated: true)
    }

    private func presentInfo() {
        let controller = AppScreenFactory.makeInfo(container: container)
        present(controller, animated: true)
    }

    private func presentUpass() {
        let upass = UpassTableViewController()
        upass.delegate = self
        let navController = UINavigationController(rootViewController: upass)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.topItem?.title = "Upass Renewal"
        navController.navigationBar.isTranslucent = true
        present(navController, animated: true, completion: nil)
    }

    private func presentFood(withSearchTerm term: String?) {
        let food = FoodTableViewController()
        food.container = container
        let navController = UINavigationController(rootViewController: food)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.topItem?.title = NSLocalizedString("food.title", comment: "")
        navController.navigationBar.isTranslucent = true
        if let keyword = term {
            food.autoSearchAction = {
                food.searchController.isActive = true
                food.searchController.searchBar.text = keyword
                DispatchQueue.main.async {
                    food.searchController.searchBar.resignFirstResponder()
                }
            }
        }
        present(navController, animated: true, completion: nil)
    }

    private func presentCalendar() {
        let can = CalendarTableViewController()
        can.container = container
        let navController = UINavigationController(rootViewController: can)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.topItem?.title = NSLocalizedString("calendar.title", comment: "")
        navController.navigationBar.isTranslucent = true
        present(navController, animated: true, completion: nil)
    }

    private func presentParking() {
        let parking = ParkingViewController()
        parking.container = container
        present(parking, animated: true, completion: nil)
    }
}

// MARK: Data

extension LandingViewController {
    private func setupNibs() {
        collectionView.register(
            UINib(nibName: ParkingStatusCollectionViewCell.nib, bundle: nil),
            forCellWithReuseIdentifier: ParkingStatusCollectionViewCell.nib
        )
        collectionView.register(
            UINib(nibName: InfoCollectionViewCell.nib, bundle: nil),
            forCellWithReuseIdentifier: InfoCollectionViewCell.nib
        )
        collectionView.register(
            UINib(nibName: CalendarCollectionViewCell.nib, bundle: nil),
            forCellWithReuseIdentifier: CalendarCollectionViewCell.nib
        )
        collectionView.register(
            UINib(nibName: UpassCollectionViewCell.nib, bundle: nil),
            forCellWithReuseIdentifier: UpassCollectionViewCell.nib
        )
        collectionView.register(
            UINib(nibName: SummaryCollectionViewCell.nib, bundle: nil),
            forCellWithReuseIdentifier: SummaryCollectionViewCell.nib
        )
        collectionView.register(
            UINib(nibName: SinglePictureStatusCollectionViewCell.nib, bundle: nil),
            forCellWithReuseIdentifier: SinglePictureStatusCollectionViewCell.nib
        )
        collectionView.register(
            UINib(nibName: LandingSectionHeader.nib, bundle: nil),
            forSupplementaryViewOfKind: LandingSectionHeader.nib,
            withReuseIdentifier: LandingSectionHeader.nib
        )
        collectionView.register(
            UINib(nibName: LandingFooter.nib, bundle: nil),
            forSupplementaryViewOfKind: LandingFooter.nib,
            withReuseIdentifier: LandingFooter.nib
        )
        collectionView.register(
            UINib(nibName: LandingHeader.nib, bundle: nil),
            forSupplementaryViewOfKind: LandingHeader.nib,
            withReuseIdentifier: LandingHeader.nib
        )
        collectionView.register(
            UINib(nibName: LongSummaryCollectionViewCell.nib, bundle: nil),
            forCellWithReuseIdentifier: LongSummaryCollectionViewCell.nib
        )
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return LandingPageModel.sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return LandingPageModel.sections[section].items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch sectionType(at: indexPath.section) {
        case .food:
            return getFoodCell(indexPath: indexPath)
        case .charger:
            return getChargerCell(indexPath: indexPath)
        case .calendar:
            return getCalendarCell(indexPath: indexPath)
        case .parking:
            return getParkingCell(indexPath: indexPath)
        case .upass:
            return getUpassCell(indexPath: indexPath)
        case .info:
            return getInfoCell(indexPath: indexPath)
        default:
            return UICollectionViewCell()
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let current = scrollView.contentOffset.y
        let transparency = max(0, current / (statusBarHeight * 3))
        statusBarShadow.alpha = min(1, transparency)
    }

    private func getFoodCell(indexPath: IndexPath) -> UICollectionViewCell {
        let foodLocations = viewModel?.foodLocations ?? []
        if foodLocations.isEmpty && isSectionLoading(.food) {
            if
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: LongSummaryCollectionViewCell.nib,
                    for: indexPath
                ) as? LongSummaryCollectionViewCell
            {
                return cell
            }
        }

        if indexPath.row == 0 {
            return foodSummaryCell(at: indexPath, foodLocations: foodLocations)
        }

        if
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SinglePictureStatusCollectionViewCell.nib,
                for: indexPath
            ) as? SinglePictureStatusCollectionViewCell
        {
            configureFoodVendorCell(cell, at: indexPath, foodLocations: foodLocations)
            return cell
        }
        return UICollectionViewCell()
    }

    private func foodSummaryCell(at indexPath: IndexPath, foodLocations: [FoodLocation]) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SummaryCollectionViewCell.nib,
                for: indexPath
            ) as? SummaryCollectionViewCell
        else {
            return UICollectionViewCell()
        }

        let openShops = foodLocations.filter(\.isOpen)
        cell.setup(type: .food, isAvailable: !openShops.isEmpty, count: openShops.count)
        return cell
    }

    private func configureFoodVendorCell(
        _ cell: SinglePictureStatusCollectionViewCell,
        at indexPath: IndexPath,
        foodLocations: [FoodLocation]
    ) {
        let selectedPlaces = featuredFoodPlaces(from: foodLocations)

        switch indexPath.row {
        case 1:
            configureFoodVendorCell(
                cell,
                isAvailable: selectedPlaces.contains { $0.name.contains("Starbucks") && $0.isOpen },
                imageName: "sb-logo",
                title: "Starbucks"
            )
        case 2:
            configureFoodVendorCell(
                cell,
                isAvailable: selectedPlaces.contains { $0.name.contains("Tim Hortons") && $0.isOpen },
                imageName: "th-logo",
                title: "Tim Hortons"
            )
        case 3:
            configureFoodVendorCell(
                cell,
                isAvailable: selectedPlaces.first(where: { $0.name == "Booster Juice Life" })?.isOpen ?? false,
                imageName: "bj-logo",
                title: "Booster Juice"
            )
        default:
            configureFoodVendorCell(
                cell,
                isAvailable: selectedPlaces.first(where: { $0.name == "Triple Os" })?.isOpen ?? false,
                imageName: "to-logo",
                title: "Triple O's"
            )
        }
    }

    private func featuredFoodPlaces(from foodLocations: [FoodLocation]) -> [FoodLocation] {
        foodLocations.filter { place in
            place.name.contains("Starbucks") ||
                place.name.contains("Tim Hortons") ||
                place.name == "Booster Juice Life" ||
                place.name == "Triple Os"
        }
    }

    private func configureFoodVendorCell(
        _ cell: SinglePictureStatusCollectionViewCell,
        isAvailable: Bool,
        imageName: String,
        title: String
    ) {
        cell.setup(
            isAvailable: isAvailable,
            image: UIImage(named: imageName) ?? UIImage(),
            title: title,
            forFood: true
        )
    }

    private func getChargerCell(indexPath: IndexPath) -> UICollectionViewCell {
        let libraryModel = viewModel?.libraryModel ?? LibraryModel()
        if libraryModel.iphones1.isEmpty && libraryModel.iphones2.isEmpty && libraryModel.andriods1.isEmpty && isSectionLoading(.charger) {
            if
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: LongSummaryCollectionViewCell.nib,
                    for: indexPath
                ) as? LongSummaryCollectionViewCell
            {
                return cell
            }
        }
        if
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SinglePictureStatusCollectionViewCell.nib,
                for: indexPath
            ) as? SinglePictureStatusCollectionViewCell
        {
            if indexPath.row == 0 {
                let model = libraryModel.iphones2
                var isA = false
                for eq in model {
                    for char in eq.details {
                        if char.isAvailable {
                            isA = true
                            break
                        }
                    }
                }
                cell.setup(isAvailable: isA, image: UIImage(named: "iphone1_png") ?? UIImage(), title: "iPhone", forFood: false)
                return cell
            } else if indexPath.row == 1 {
                let model = libraryModel.macs1
                var isA = false
                for eq in model {
                    for char in eq.details {
                        if char.isAvailable {
                            isA = true
                            break
                        }
                    }
                }
                cell.setup(isAvailable: isA, image: UIImage(named: "mac_png") ?? UIImage(), title: "Mac", forFood: false)
                return cell
            } else {
                let model = libraryModel.andriods2
                var isA = false
                for eq in model {
                    for char in eq.details {
                        if char.isAvailable {
                            isA = true
                            break
                        }
                    }
                }
                cell.setup(isAvailable: isA, image: UIImage(named: "android1_png") ?? UIImage(), title: "Android", forFood: false)
                return cell
            }
        }
        return UICollectionViewCell()
    }

    private func getCalendarCell(indexPath: IndexPath) -> UICollectionViewCell {
        let calendarEvents = viewModel?.calendarEvents ?? []
        let model: CampusCalendarEvent? = calendarEvents.filter { day in
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            formatter.dateFormat = "dd"
            let dayString = formatter.string(from: day.date)
            return Int(dayString) == Date().get(.day)
        }.first

        if calendarEvents.isEmpty && isSectionLoading(.calendar) {
            if
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: LongSummaryCollectionViewCell.nib,
                    for: indexPath
                ) as? LongSummaryCollectionViewCell
            {
                return cell
            }
        } else if indexPath.row == 0 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SummaryCollectionViewCell.nib, for: indexPath) as? SummaryCollectionViewCell {
                if let today = model {
                    cell.setup(
                        type: .calendar,
                        isAvailable: !today.events.isEmpty,
                        count: today.events.count
                    )
                } else {
                    cell.setup(
                        type: .calendar,
                        isAvailable: false,
                        count: 0
                    )
                }
                return cell
            }
        } else {
            if
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CalendarCollectionViewCell.nib,
                    for: indexPath
                ) as? CalendarCollectionViewCell
            {
                cell.setup(for: model?.events ?? [])
                return cell
            }
        }
        return UICollectionViewCell()
    }

    private func getUpassCell(indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UpassCollectionViewCell.nib, for: indexPath) as? UpassCollectionViewCell {
            cell.setup()
            return cell
        }
        return UICollectionViewCell()
    }

    private func getParkingCell(indexPath: IndexPath) -> UICollectionViewCell {
        let parkingData = viewModel?.parkingData ?? []
        if parkingData.isEmpty && isSectionLoading(.parking) {
            if
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: LongSummaryCollectionViewCell.nib,
                    for: indexPath
                ) as? LongSummaryCollectionViewCell
            {
                return cell
            }
        } else {
            let model = parkingData
            if indexPath.row == 0 {
                var count = 0
                for lot in model {
                    if lot.status.first == .good {
                        count += 1
                    }
                }
                if
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: SummaryCollectionViewCell.nib,
                        for: indexPath
                    ) as? SummaryCollectionViewCell
                {
                    cell.setup(type: .parkade, isAvailable: count > 0, count: count)
                    return cell
                }
            } else {
                if indexPath.row - 1 < model.count {
                    if
                        let cell = collectionView.dequeueReusableCell(
                            withReuseIdentifier: ParkingStatusCollectionViewCell.nib,
                            for: indexPath
                        ) as? ParkingStatusCollectionViewCell
                    {
                        let lot = model[indexPath.row - 1]
                        cell.setup(for: lot)
                        return cell
                    }
                }
                if
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: ParkingStatusCollectionViewCell.nib,
                        for: indexPath
                    ) as? ParkingStatusCollectionViewCell
                {
                    cell.setup(for: ParkingAnnotation(lotName: .unknown, status: [.full, .full]))
                    return cell
                }
            }
        }
        return UICollectionViewCell()
    }

    private func getInfoCell(indexPath: IndexPath) -> UICollectionViewCell {
        let notifications = viewModel?.notifications ?? []
        if notifications.isEmpty && isSectionLoading(.info) {
            if
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: LongSummaryCollectionViewCell.nib,
                    for: indexPath
                ) as? LongSummaryCollectionViewCell
            {
                return cell
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InfoCollectionViewCell.nib, for: indexPath) as? InfoCollectionViewCell {
                if !(viewModel?.isSectionAvailable(.info) ?? false) {
                    cell.setup(for: nil)
                } else {
                    cell.setup(for: notifications)
                }

                return cell
            }
        }
        return UICollectionViewCell()
    }
}

// MARK: Version Check

extension LandingViewController {
    /// update alert && show what's new
    func checkVersion() {
        AppVersionCoordinator.check(
            with: container?.sanityCheckService,
            onResult: { [weak self] check in
                guard let self else { return }
                if let notice = check.notice, notice.shouldShow(for: AppVersionCoordinator.currentVersion) {
                    self.statusNoticeMessage = "\(notice.title): \(notice.detail)"
                    self.statusNoticeStyle = .offline
                    self.updateGlobalHeaderNotice()
                } else {
                    self.statusNoticeMessage = nil
                    self.updateGlobalHeaderNotice()
                }
            },
            onNewVersion: { [weak self] in
                guard let self else { return }
                let alert = UIAlertController(
                    title: "Update Available",
                    message: "A new version of myUBC is available on the App Store. Would you like to update now?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Update Now", style: .default, handler: { _ in
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id1498544052") {
                        UIApplication.shared.open(url)
                    }
                }))
                alert.addAction(UIAlertAction(title: "Later", style: .default, handler: { _ in
                    let reminder = UIAlertController(
                        title: "Please Update Soon",
                        message: "UBC websites change periodically. Keeping myUBC up to date helps ensure that data and features continue to work correctly.",
                        preferredStyle: .alert
                    )
                    reminder.addAction(UIAlertAction(title: NSLocalizedString("alert.ok", comment: ""), style: .default))
                    self.present(reminder, animated: true)
                }))
                self.present(alert, animated: true)
            },
            onNoNewVersion: { [weak self] in
                guard let self else { return }
                AppVersionCoordinator.presentWhatsNewIfNeeded(from: self)
            }
        )
    }
}

// MARK: Collection Layout

extension LandingViewController {
    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    )
        -> UICollectionReusableView
    {
        if kind == LandingSectionHeader.nib {
            return sectionHeaderView(for: collectionView, kind: kind, indexPath: indexPath)
        } else if kind == LandingFooter.nib {
            return footerView(for: collectionView, kind: kind, indexPath: indexPath)
        } else if kind == LandingHeader.nib {
            return headerView(for: collectionView, kind: kind, indexPath: indexPath)
        } else { // No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }

    private func sectionHeaderView(
        for collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath
    )
        -> UICollectionReusableView
    {
        guard
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LandingSectionHeader.nib,
                for: indexPath
            ) as? LandingSectionHeader
        else {
            return UICollectionReusableView()
        }
        sectionHeader.title.text = LandingPageModel.sections[safe: indexPath.section]?.sectionTitle
        sectionHeader.button.setTitle(LandingPageModel.sections[safe: indexPath.section]?.linkLabel, for: .normal)

        let sectionType = sectionType(at: indexPath.section)
        sectionHeader.setup(
            hasError: !(sectionType.flatMap { self.viewModel?.isSectionAvailable($0) } ?? true),
            action: sectionType.flatMap { self.sectionAction[$0] },
            errorAction: { [weak self] in
                self?.generatorNotice.notificationOccurred(.error)
                self?.presentError(.unknown)
            }
        )
        return sectionHeader
    }

    private func footerView(
        for collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath
    )
        -> UICollectionReusableView
    {
        guard
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LandingFooter.nib,
                for: indexPath
            ) as? LandingFooter
        else {
            return UICollectionReusableView()
        }
        footer.action = {
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id1498544052") {
                UIApplication.shared.open(url)
            }
        }
        return footer
    }

    private func headerView(
        for collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath
    )
        -> UICollectionReusableView
    {
        guard
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LandingHeader.nib,
                for: indexPath
            ) as? LandingHeader
        else {
            return UICollectionReusableView()
        }
        globalHeader = header
        header.accessibilityIdentifier = "landing.header"
        header.configureStatusMessage(statusNoticeMessage, style: statusNoticeStyle)
        header.action = { [weak self] in
            self?.presentReminders()
        }
        header.badgeCheck()
        return header
    }

    private func presentReminders() {
        let reminder = RemindersTableViewController()
        reminder.delegate = self
        let navController = UINavigationController(rootViewController: reminder)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.topItem?.title = "Reminder"
        navController.navigationBar.isTranslucent = true
        reminder.navigateCollection = { [weak self] in
            DispatchQueue.main.async {
                self?.scrollToUpassSection()
            }
        }
        reminder.showUpassBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.presentUpass()
            }
        }
        generatorImpact.impactOccurred()
        present(navController, animated: true)
    }

    private func scrollToUpassSection() {
        guard let upassIndex = sectionIndex(for: .upass) else {
            return
        }
        collectionView.scrollToItem(
            at: IndexPath(row: 0, section: upassIndex),
            at: .centeredHorizontally,
            animated: true
        )
    }

    private func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (
            sectionIndex: Int,
            _: NSCollectionLayoutEnvironment
        )
            -> NSCollectionLayoutSection? in
        let section = self.getSectionLayout(for: sectionIndex)

        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 0
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20)

        let titleSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let titleSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: titleSize,
            elementKind: LandingSectionHeader.nib,
            alignment: .top
        )
        section.boundarySupplementaryItems = [titleSupplementary]
        return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 0
        config.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(130)),
                elementKind: LandingHeader.nib,
                alignment: .top
            ),
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100)),
                elementKind: LandingFooter.nib,
                alignment: .bottom
            )
        ]

        return UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider, configuration: config
        )
    }

    private func getSectionLayout(for section: Int) -> NSCollectionLayoutSection {
        let globalItemHeight: CGFloat = 170.0

        let landingSection = LandingPageModel.sections[section]
        var largeWidth: CGFloat = (landingSection.type == .upass || landingSection.type == .info) ?
            screenWidth * 0.9 : (globalItemHeight * 2)
        // if ipad, use standard sizes
        largeWidth = (UIDevice.current.userInterfaceIdiom == .pad) ? (globalItemHeight * 2) : largeWidth
        var groupArray: [NSCollectionLayoutGroup] = []

        for item in landingSection.items {
            if item.isSummary {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(largeWidth),
                    heightDimension: .absolute(globalItemHeight)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize1 = NSCollectionLayoutSize(
                    widthDimension: .absolute(largeWidth),
                    heightDimension: .absolute(globalItemHeight)
                )
                let group1 = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize1, subitems: [item])
                groupArray.append(group1)
            } else {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(globalItemHeight),
                    heightDimension: .absolute(globalItemHeight)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize2 = NSCollectionLayoutSize(
                    widthDimension: .absolute(globalItemHeight),
                    heightDimension: .absolute(globalItemHeight)
                )
                let group2 = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize2, subitems: [item])
                groupArray.append(group2)
            }
        }

        let groupSize0 = NSCollectionLayoutSize(
            widthDimension: .estimated(largeWidth),
            heightDimension: .absolute(globalItemHeight)
        )
        let group0 = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize0, subitems: groupArray)
        return NSCollectionLayoutSection(group: group0)
    }
}

extension LandingViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        globalHeader?.badgeCheck()
    }
}

// swiftlint:enable file_length
