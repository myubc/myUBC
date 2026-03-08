//
//  ChargerTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-01-22.
//

import Lottie
import UIKit

@MainActor
class ChargerTableViewController: UITableViewController, AppContainerInjectable {
    var container: AppContainer?
    private var viewModel: ChargerViewModel?
    private var libraryModel = LibraryModel()
    var preloadedLibraryModel: LibraryModel?
    var preloadedLastUpdated: Date?

    @IBOutlet var refreshBtn: UIBarButtonItem!

    private let refreshComponent = UIRefreshControl()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)
    var doneBlock: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let container = container {
            viewModel = ChargerViewModel(service: container.libraryService)
        }
        setupNavigation()
        if let preloadedLibraryModel, !isLibraryModelEmpty(preloadedLibraryModel) {
            libraryModel = preloadedLibraryModel
        }
        setUpTableView()
        if isLibraryModelEmpty() {
            requestLibraryData(forceRefresh: false)
        } else {
            tableView.reloadData()
            setTableFooterStatusMessage(chargerFreshnessMessage())
        }
    }

    private func setupNavigation() {
        let refresh = UIBarButtonItem.appNavIcon(
            systemName: "arrow.clockwise",
            target: self,
            action: #selector(didSelectRefresh(_:)),
            accessibilityLabel: "Refresh charger status"
        )
        let close = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(didClose(_:)),
            accessibilityLabel: "Close charger status"
        )
        navigationItem.setLeftBarButton(refresh, animated: false)
        navigationItem.setRightBarButton(close, animated: false)
        refreshBtn = refresh
    }

    private func isLibraryModelEmpty() -> Bool {
        isLibraryModelEmpty(libraryModel)
    }

    private func isLibraryModelEmpty(_ model: LibraryModel) -> Bool {
        return model.iphones1.isEmpty
            && model.iphones2.isEmpty
            && model.andriods1.isEmpty
            && model.andriods2.isEmpty
            && model.macs1.isEmpty
            && model.macs2.isEmpty
    }

    /// solve the problem that shadow did not appear in correct size on first load
    override func viewWillLayoutSubviews() {
        for cell in tableView.visibleCells {
            guard let cell = cell as? ChargerTableViewCell else {
                return
            }
            setUpShadow(forCell: cell)
        }
    }

    func setUpTableView() {
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        tableView.insetsContentViewsToSafeArea = true
        tableView.register(
            UINib(nibName: Constants.chargerCellNib, bundle: nil),
            forCellReuseIdentifier: Constants.chargerCellIdentifier
        )
        tableView.rowHeight = 146
        tableView.estimatedRowHeight = 146
        refreshComponent.addTarget(self, action: #selector(didSelectRefresh(_:)), for: .valueChanged)
        refreshComponent.attributedTitle = NSAttributedString(string: "Pull to Update")
        // tableView.refreshControl = refreshComponent
    }

    func setUpShadow(forCell cell: ChargerTableViewCell) {
        let shadowPath = UIBezierPath(roundedRect: cell.shadowView.bounds, cornerRadius: 14.0)
        cell.shadowView.layer.masksToBounds = false
        cell.shadowView.layer.shadowRadius = 8.0
        cell.shadowView.layer.shadowColor = UIColor.darkGray.cgColor
        cell.shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
        cell.shadowView.layer.shadowOpacity = 0.2
        cell.shadowView.layer.shadowPath = shadowPath.cgPath

        // cell.clipsToBounds = false
        // cell.layer.masksToBounds = false
    }

    func requestLibraryData(forceRefresh: Bool = false) {
        refreshBtn.isEnabled = false
        Task {
            guard let viewModel = viewModel else { return }
            let result = await viewModel.load(forceRefresh: forceRefresh)
            if case .success = result {
                self.libraryModel = viewModel.model
            }
            await MainActor.run {
                if let banner = viewModel.banner {
                    self.setTableFooterStatusMessage(banner.message)
                } else {
                    self.setTableFooterStatusMessage(self.chargerFreshnessMessage())
                }
                if case let .failure(error) = result {
                    self.presentError(error)
                }
                self.hideLoadingState()
                self.refreshBtn.isEnabled = true
                self.generatorImpact.impactOccurred()
                self.tableView.reloadData()
                self.refreshComponent.endRefreshing()
                self.tableView.isUserInteractionEnabled = true
            }
        }
    }

    @IBAction func didClose(_ sender: Any) {
        doneBlock?()
        generatorImpact.impactOccurred()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func didSelectRefresh(_ sender: Any) {
        generatorImpact.impactOccurred()
        for cell in tableView.visibleCells {
            guard let cell = cell as? ChargerTableViewCell else {
                return
            }
            tableView.isUserInteractionEnabled = false
            cell.loadingBaseView.alpha = 0
            cell.loadingBaseView.isHidden = false
            let starAnimationView = AnimationView(name: "loading")
            starAnimationView.frame = cell.loadingBaseView.bounds
            cell.loadingBaseView.addSubview(starAnimationView)
            starAnimationView.alpha = 0
            starAnimationView.loopMode = .loop
            starAnimationView.play()
            UIView.animate(withDuration: 1, animations: {
                cell.loadingBaseView.alpha = 0.8
                starAnimationView.alpha = 1
            }, completion: { _ in
                if cell == self.tableView.visibleCells.first {
                    self.requestLibraryData(forceRefresh: true)
                }
            })
        }
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

    private func chargerFreshnessMessage() -> String? {
        if let message = CacheBanner.lastUpdatedMessage(from: viewModel?.lastUpdated) {
            return message
        }
        if let message = CacheBanner.lastUpdatedMessage(from: preloadedLastUpdated) {
            return message
        }
        return nil
    }

    private func hideLoadingState() {
        for cell in tableView.visibleCells {
            guard let chargerCell = cell as? ChargerTableViewCell else { continue }
            chargerCell.loadingBaseView.subviews.forEach { $0.removeFromSuperview() }
            chargerCell.loadingBaseView.isHidden = true
        }
    }

    private func availabilityFlags() -> [Bool]? {
        let groups = [
            libraryModel.iphones1,
            libraryModel.iphones2,
            libraryModel.andriods1,
            libraryModel.andriods2,
            libraryModel.macs1,
            libraryModel.macs2
        ]
        guard groups.contains(where: { !$0.isEmpty }) else {
            return nil
        }
        return groups.map { equipmentGroup in
            equipmentGroup.contains { equipment in
                equipment.details.contains(where: \.isAvailable)
            }
        }
    }
}

extension ChargerTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return LibraryConstants.data.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let content = LibraryConstants.data[indexPath.row],
            let title = content["title"] else { return }

        let detailContent: [Equipment]
        let isInIKB: Bool
        switch indexPath.row {
        case 0:
            detailContent = libraryModel.iphones1
            isInIKB = true
        case 1:
            detailContent = libraryModel.iphones2
            isInIKB = false
        case 2:
            detailContent = libraryModel.andriods1
            isInIKB = true
        case 3:
            detailContent = libraryModel.andriods2
            isInIKB = false
        case 4:
            detailContent = libraryModel.macs1
            isInIKB = true
        case 5:
            detailContent = libraryModel.macs2
            isInIKB = false
        default:
            detailContent = []
            isInIKB = false
        }

        let controller = AppScreenFactory.makeChargerDetail(
            container: container,
            libraryModel: libraryModel,
            context: .init(
                title: title,
                selectedIndex: indexPath.row,
                content: detailContent,
                isInIKB: isInIKB
            )
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if
            let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.chargerCellIdentifier,
                for: indexPath
            ) as? ChargerTableViewCell
        {
            let availability = availabilityFlags()
            setUpShadow(forCell: cell)
            if
                let content = LibraryConstants.data[indexPath.row],
                let text = content["title"],
                let location = content["location"],
                let img = content["img"]
            {
                cell.title.text = text
                cell.location.text = location
                cell.contentImg.image = UIImage(named: img)
                cell.contentImg.backgroundColor = LibraryConstants.backgroundColors[indexPath.row]

                if let availability, let isAvailable = availability[safe: indexPath.row] {
                    cell.statusIcon.setImage(
                        UIImage(systemName: isAvailable ? Constants.foodOpenIcon : Constants.foodClosedIcon),
                        for: .normal
                    )
                    cell.statusIcon.tintColor = isAvailable
                        ? #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1)
                        : #colorLiteral(red: 0.8588235294, green: 0.3607843137, blue: 0, alpha: 1)
                }
            }
            cell.layoutIfNeeded()
            return cell
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ChargerTableViewCell {
            shrink(down: true, cell: cell)
        }
    }

    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ChargerTableViewCell {
            shrink(down: false, cell: cell)
        }
    }
}
