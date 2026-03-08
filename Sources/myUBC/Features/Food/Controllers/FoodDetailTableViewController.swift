//
//  FoodDetailTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-10-18.
//

import MapKit
import UIKit

@MainActor
class FoodDetailTableViewController: UITableViewController, FoodDetailProtocol, AppContainerInjectable {
    var container: AppContainer?
    var detailItem: FoodDetailItem?
    var target: FoodLocation?
    var targetDetail: FoodItem?
    private var viewModel: FoodDetailViewModel?

    private var heightAtIndexPath = NSMutableDictionary()

    override func viewDidLoad() {
        super.viewDidLoad()
        if let container = container {
            viewModel = FoodDetailViewModel(service: container.foodDetailService)
        }
        setupTable()
        setupModel()
    }

    func setupModel() {
        let effect = (traitCollection.userInterfaceStyle == .dark) ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
        let loadingView = UIViewController.displaySpinner(onView: navigationController?.view ?? view, effect: effect)
        tableView.isUserInteractionEnabled = false
        guard let url = targetDetail?.url, let viewModel else {
            UIViewController.removeSpinner(spinner: loadingView)
            tableView.isUserInteractionEnabled = true
            presentError(.invalidResponse) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
            return
        }
        Task {
            let result = await viewModel.load(url: url)
            await MainActor.run {
                switch result {
                case .success:
                    self.detailItem = viewModel.detail
                    if let banner = viewModel.banner {
                        self.showStatusBanner(message: banner.message, style: banner.style)
                    } else {
                        self.hideStatusBanner()
                    }
                    self.tableView.reloadData()
                    self.tableView.isUserInteractionEnabled = true
                    UIViewController.removeSpinner(spinner: loadingView)
                case let .failure(error):
                    UIViewController.removeSpinner(spinner: loadingView)
                    self.presentError(error) { [weak self] in
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }

    func setupTable() {
        let close = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(dismissView),
            accessibilityLabel: "Close food details"
        )
        navigationItem.setRightBarButton(close, animated: true)
        tableView?.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag
        tableView.insetsContentViewsToSafeArea = true
        tableView.register(
            UINib(
                nibName: FoodDetailTableViewCell.nib,
                bundle: nil
            ),
            forCellReuseIdentifier: FoodDetailTableViewCell.nib
        )
        tableView.register(
            UINib(
                nibName: FoodDetailBottomTableViewCell.nib,
                bundle: nil
            ),
            forCellReuseIdentifier: FoodDetailBottomTableViewCell.nib
        )
        tableView.register(
            UINib(
                nibName: FoodImageTableViewCell.nib,
                bundle: nil
            ),
            forCellReuseIdentifier: FoodImageTableViewCell.nib
        )
        tableView.register(
            UINib(
                nibName: DetailMapTableViewCell.nib,
                bundle: nil
            ),
            forCellReuseIdentifier: DetailMapTableViewCell.nib
        )
    }

    func didLearnMore() {
        guard let href = targetDetail?.url else {
            return
        }
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = .ubc(url: href, address: Constants.foodBaseURL)
        present(webView, animated: true, completion: nil)
    }

    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }

    func navigationMap() {
        let rawAddress = detailItem?.address ?? targetDetail?.address ?? ""
        guard !rawAddress.isEmpty else {
            return
        }
        let normalized = rawAddress
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\n", with: ", ")
        let location = normalized + ", UBC, Vancouver, BC, Canada"
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] placemarks, _ in
            if
                let placemark = placemarks?.first,
                let location = placemark.location
            {
                guard let self else {
                    return
                }
                let launchOptions = [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
                ]
                let mkPlace = MKPlacemark(coordinate: location.coordinate)

                let destination = MKMapItem(placemark: mkPlace)
                Task { @MainActor in
                    destination.name = self.targetDetail?.spaceTitle
                    MKMapItem.openMaps(with: [MKMapItem.forCurrentLocation(), destination], launchOptions: launchOptions)
                }
            }
        }
    }
}

extension FoodDetailTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let images = detailItem?.images else {
            return 1
        }
        return 3 + images.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return descriptionCell(indexPath: indexPath)
        } else if indexPath.row == (tableView.numberOfRows(inSection: 0) - 1) {
            return bottonBtn(indexPath: indexPath)
        } else if indexPath.row == (tableView.numberOfRows(inSection: 0) - 2) {
            return mapCell(indexPath: indexPath)
        } else {
            return imageCell(indexPath: indexPath)
        }
    }

    private func descriptionCell(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FoodDetailTableViewCell.nib, for: indexPath) as? FoodDetailTableViewCell else {
            return UITableViewCell()
        }

        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        guard let status = target, let info = targetDetail else {
            return cell
        }

        cell.setupStatus(isOpen: status.isOpen, fullStatus: status.statusText)
        cell.setupLogo(src: status.name, url: status.url, slug: status.slug)
        cell.setupRating(rating: info.rating)

        guard let detail = detailItem else {
            cell.setupDetail(detail: info.address)
            cell.setupCard(isOn: false)
            cell.setupCarry(isOn: false)
            cell.setupMeal(isOn: false)
            return cell
        }

        let summary = detail.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackAddress = detail.address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? info.address
        cell.setupDetail(detail: summary.isEmpty ? fallbackAddress : summary)
        cell.setupCard(isOn: detail.ubccard)
        cell.setupCarry(isOn: detail.carryover)
        cell.setupMeal(isOn: detail.mealplan)
        return cell
    }

    private func bottonBtn(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FoodDetailBottomTableViewCell.nib, for: indexPath) as? FoodDetailBottomTableViewCell
        else {
            return UITableViewCell()
        }
        cell.foodProtocol = self
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }

    private func imageCell(indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: FoodImageTableViewCell.nib, for: indexPath) as? FoodImageTableViewCell,
            let url = detailItem?.images[indexPath.row - 1]
        else {
            return UITableViewCell()
        }
        cell.setupImage(url: url)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }

    private func mapCell(indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: DetailMapTableViewCell.nib, for: indexPath) as? DetailMapTableViewCell,
            let address = targetDetail?.address
        else {
            return UITableViewCell()
        }
        cell.foodProtocol = self
        cell.setupLocation(address: address)
        cell.setupMap()
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
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

@MainActor
protocol FoodDetailProtocol: AnyObject {
    func didLearnMore()
    func navigationMap()
}
