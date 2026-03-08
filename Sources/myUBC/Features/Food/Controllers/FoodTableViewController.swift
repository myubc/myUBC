//
//  FoodTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-03-26.
//

import UIKit

@MainActor
class FoodTableViewController: UITableViewController, UISearchResultsUpdating, FoodTableViewControllerProtocol, UISearchControllerDelegate,
    AppContainerInjectable
{
    var container: AppContainer?
    private var viewModel: FoodListViewModel?
    private let screenModel = FoodListScreenModel()
    private var heightAtIndexPath = NSMutableDictionary()

    private let generatorNotice = UINotificationFeedbackGenerator()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)

    var loadingView: UIAlertController?
    let searchController = UISearchController(searchResultsController: nil)

    var autoSearchAction: (() -> Void)?

    private func loadFoods(forceRefresh: Bool = false) async -> Bool {
        guard let viewModel else { return false }
        let result = await viewModel.load(forceRefresh: forceRefresh)
        switch result {
        case .success:
            screenModel.updateFoods(viewModel.foods)
            setTableFooterStatusMessage(viewModel.banner?.message ?? CacheBanner.lastUpdatedMessage(from: viewModel.lastUpdated))
            return true
        case .failure:
            setTableFooterStatusMessage(viewModel.banner?.message)
            return false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let container = container {
            viewModel = FoodListViewModel(service: container.foodService)
        }
        setupTable()
        setupSearch()
        setupNavigation()
        loadInitialData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoSearchAction?()
    }

    func loadInitialData() {
        tableView.showsVerticalScrollIndicator = false
        tableView.isUserInteractionEnabled = false
        let cells = tableView.visibleCells
        for item in cells {
            if let cell = item as? EmptyTableViewCell {
                cell.showLoading()
            }
        }
        Task {
            _ = await loadFoods()
            await MainActor.run {
                self.tableView.reloadData()
                self.tableView.isUserInteractionEnabled = true
                self.animateTable()
                self.tableView.showsVerticalScrollIndicator = true
            }
        }
    }

    func setupNavigation() {
        let close = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(dismissView),
            accessibilityLabel: "Close food services"
        )
        let search = UIBarButtonItem.appNavIcon(
            systemName: "magnifyingglass",
            target: self,
            action: #selector(didTapSearch),
            accessibilityLabel: "Search restaurants"
        )
        search.tintColor = .clear
        navigationItem.setRightBarButton(close, animated: true)
        navigationItem.setLeftBarButton(search, animated: true)
    }

    func setupTable() {
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView?.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag
        tableView.insetsContentViewsToSafeArea = true
        tableView.register(
            UINib(nibName: EmptyTableViewCell.nib, bundle: nil),
            forCellReuseIdentifier: EmptyTableViewCell.nib
        )
        tableView.register(
            UINib(nibName: ControlTableViewCell.nib, bundle: nil),
            forCellReuseIdentifier: ControlTableViewCell.nib
        )
        tableView.register(
            UINib(nibName: FoodTableViewCell.nib, bundle: nil),
            forCellReuseIdentifier: FoodTableViewCell.nib
        )
    }

    func setupSearch() {
        let directionalMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        searchController.searchBar.directionalLayoutMargins = directionalMargins
        searchController.searchBar.autocorrectionType = .yes
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.backgroundColor = .systemBackground
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        searchController.delegate = self

        let view = UIView()
        view.backgroundColor = .systemBackground
        tableView.backgroundView = view
        tableView.tableHeaderView?.backgroundColor = .systemBackground
        tableView.tableHeaderView = searchController.searchBar
    }

    @objc func dismissView() {
        generatorImpact.impactOccurred()
        dismiss(animated: true, completion: nil)
    }

    @objc func refresh() {
        generatorImpact.impactOccurred()
        tableView.showsVerticalScrollIndicator = false
        tableView.isUserInteractionEnabled = false
        let cells = tableView.visibleCells
        for item in cells {
            if let cell = item as? FoodTableViewCell {
                cell.showLoadingView()
            } else if let cell = item as? EmptyTableViewCell {
                cell.showLoading()
            }
        }

        Task {
            let isOK = await loadFoods(forceRefresh: true)
            if !isOK {
                self.screenModel.updateFoods([])
            }
            await MainActor.run {
                self.tableView.contentOffset = CGPoint(x: 0, y: self.searchController.searchBar.frame.height)
                self.tableView.reloadData()
                self.tableView.isUserInteractionEnabled = true
                self.animateTable()
                self.tableView.showsVerticalScrollIndicator = true
                self.generatorNotice.notificationOccurred(.success)
            }
        }
    }

    func shrink(down: Bool, cell: UITableViewCell) {
        UIView.animate(withDuration: 0.2) {
            if down {
                cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } else {
                cell.transform = .identity
            }
        }
    }

    func filter(toShowAll: Bool) {
        generatorImpact.impactOccurred()
        screenModel.setShowAll(toShowAll)
        tableView.reloadData()
        animateTable()
    }

    @objc func didTapSearch() {
        tableView.setContentOffset(.zero, animated: false)
        searchController.isActive = true
    }

    private func animateTable() {
        guard tableView.visibleCells.count >= 2 else {
            return
        }

        guard tableView.visibleCells[1] is FoodTableViewCell else {
            return
        }

        tableView.isUserInteractionEnabled = false

        // Animate Table Cells
        let cells = tableView.visibleCells
        let tableHeight: CGFloat = tableView.bounds.size.height

        for i in cells {
            if i != cells.first {
                let cell: UITableViewCell = i as UITableViewCell
                cell.transform = CGAffineTransform(
                    translationX: 0,
                    y: tableHeight
                )
            }
        }

        var index = 0
        for a in cells {
            if a != cells.first {
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
            }
            index += 1
        }
    }

    @objc func showFeedmenow() {
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = .ubc(url: Constants.foodLink, address: Constants.foodBaseURL)
        present(webView, animated: true, completion: nil)
    }

    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            screenModel.setSearchQuery(searchText)
            // Reload the table view with the search result data.
            tableView.reloadData()
            tableView.layoutSubviews()
            tableView.setNeedsLayout()
        }
    }

    // MARK: - UISearchResultsUpdating method

    func filterContent(for searchText: String) {
        screenModel.setSearchQuery(searchText)
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        screenModel.setSearching(true)
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        screenModel.setSearching(false)
        tableView.reloadData()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > tableView.tableHeaderView?.frame.size.height ?? 0 {
            if navigationItem.leftBarButtonItem?.isEnabled ?? false {
                return
            }
            navigationItem.leftBarButtonItem?.isEnabled = true
            UIView.animate(withDuration: 1) {
                self.navigationItem.leftBarButtonItem?.tintColor = nil
            }
        } else {
            if !(navigationItem.leftBarButtonItem?.isEnabled ?? false) {
                return
            }
            navigationItem.leftBarButtonItem?.isEnabled = false
            UIView.animate(withDuration: 1) {
                self.navigationItem.leftBarButtonItem?.tintColor = .clear
            }
        }
    }
}

@MainActor
protocol FoodTableViewControllerProtocol: AnyObject {
    func filter(toShowAll: Bool)
    func showFeedmenow()
}

extension FoodTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        screenModel.tableRowCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if screenModel.isSearching { return getFoodCell(indexPath: indexPath) }

        if indexPath.row == 0 { return getControlCell(indexPath: indexPath) }

        if screenModel.visibleFoods.isEmpty {
            return getEmptyCell(indexPath: indexPath)
        }

        return getFoodCell(indexPath: indexPath)
    }

    private func getEmptyCell(indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: EmptyTableViewCell.nib,
                for: indexPath
            ) as? EmptyTableViewCell
        else {
            return UITableViewCell()
        }
        cell.webapgeBtn.addTarget(self, action: #selector(showFeedmenow), for: .touchUpInside)
        cell.setup(isError: screenModel.isShowingLoadingEmptyState)

        if screenModel.isShowingLoadingEmptyState {
            cell.title.text = "Please Wait"
            cell.subtitle.text = "UBC Food can be slow to load. This may take up to 20 seconds. Please bear with us."
            cell.webapgeBtn.isHidden = true
            cell.iconView.isHidden = true
        } else {
            cell.webapgeBtn.isHidden = false
            cell.iconView.isHidden = false
        }

        return cell
    }

    private func getControlCell(indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ControlTableViewCell.nib,
                for: indexPath
            ) as? ControlTableViewCell
        else {
            return UITableViewCell()
        }
        cell.controller = self
        return cell
    }

    private func getFoodCell(indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: FoodTableViewCell.nib,
                for: indexPath
            ) as? FoodTableViewCell
        else {
            return UITableViewCell()
        }

        guard let model = screenModel.food(atRow: indexPath.row) else {
            return UITableViewCell()
        }
        cell.setup(model: model)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (tableView.cellForRow(at: indexPath) as? FoodTableViewCell) != nil else {
            return
        }

        let detailController = FoodDetailTableViewController(nibName: Constants.foodDetail, bundle: nil)
        detailController.container = container
        detailController.target = screenModel.food(atRow: indexPath.row)
        if let target = detailController.target {
            detailController.targetDetail = FoodItem(
                spaceTitle: target.name,
                url: target.url,
                tvalue: "",
                address: target.address,
                rating: target.rating
            )
        }

        let navController = UINavigationController(rootViewController: detailController)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.topItem?.title = "Details"
        navController.navigationBar.isTranslucent = true

        present(navController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FoodTableViewCell {
            shrink(down: true, cell: cell)
        }
    }

    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FoodTableViewCell {
            shrink(down: false, cell: cell)
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = heightAtIndexPath.object(forKey: indexPath) as? NSNumber {
            return CGFloat(height.floatValue)
        } else {
            return UITableView.automaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let height = NSNumber(value: Float(cell.frame.size.height))
        heightAtIndexPath.setObject(height, forKey: indexPath as NSCopying)
    }
}
