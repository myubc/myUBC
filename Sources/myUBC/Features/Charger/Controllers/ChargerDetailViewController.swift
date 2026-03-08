//
//  ChargerDetailViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-01-27.
//

import UIKit

@MainActor
class ChargerDetailViewController: UITableViewController, DeviceProtocol {
    var model: ChargerDetailViewModel?
    var container: AppContainer?
    var libraryModel = LibraryModel()
    var isInIKB: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigation()
    }

    func setupTableView() {
        tableView.register(
            UINib(nibName: Constants.chargerCellDetailNib_mapCell, bundle: nil),
            forCellReuseIdentifier: Constants.chargerCellDetailIdentifier_mapCell
        )
        tableView.register(
            UINib(nibName: Constants.chargerCellDetailNib_deviceCell, bundle: nil),
            forCellReuseIdentifier: Constants.chargerCellDetailIdentifier_deviceCell
        )
        tableView.register(
            UINib(nibName: Constants.chargerCellDetailNib_errorCell, bundle: nil),
            forCellReuseIdentifier: Constants.chargerCellDetailIdentifier_errorCell
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
    }

    func setupNavigation() {
        navigationItem.title = model?.title
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        for cell in tableView.visibleCells {
            guard let cell = cell as? MapTableViewCell else {
                return
            }
            cell.clipsToBounds = false
            cell.setupShadow()
        }
    }

    // MARK: - Navigation

    /// In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

        if let count = model?.content.count {
            return (count > 1) ? count + 1 : 2
        }

        return 2
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            return UIScreen.main.bounds.height / 2.5
        default:
            return UITableView.automaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let model = model?.content else {
            return UITableViewCell()
        }

        if indexPath.row == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: Constants.chargerCellDetailIdentifier_mapCell) as? MapTableViewCell {
                cell.isInIKB = isInIKB
                return cell
            }
        } else if model.isEmpty && tableView.numberOfRows(inSection: 0) == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: Constants.chargerCellDetailIdentifier_errorCell) as? ErrorTableViewCell {
                cell.detailView = self
                var url = ""
                switch self.model?.selectedIndex {
                case 0:
                    url = Constants.libraryURL_iphone1
                case 1:
                    url = Constants.libraryURL_iphone2
                case 2:
                    url = Constants.libraryURL_android1
                case 3:
                    url = Constants.libraryURL_android2
                case 4:
                    url = Constants.libraryURL_mac1
                case 5:
                    url = Constants.libraryURL_mac2
                default:
                    url = Constants.libraryURL_iphone1
                }
                cell.fallbackURL = url
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: Constants.chargerCellDetailIdentifier_deviceCell) as? DeviceDetailCell {
                cell.setup(title: model[indexPath.row - 1].name, items: model[indexPath.row - 1].details)
                cell.deviceProtocol = self
                return cell
            }
        }

        return UITableViewCell()
    }

    func fallback(for url: String) {
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = .ubcReadOnly(url: url)
        present(webView, animated: true, completion: nil)
    }

    func pushCheckoutView() {
        navigationController?.pushViewController(AppScreenFactory.makeChargerCheckout(), animated: true)
    }
}

@MainActor
protocol DeviceProtocol: AnyObject {
    func pushCheckoutView()
}
