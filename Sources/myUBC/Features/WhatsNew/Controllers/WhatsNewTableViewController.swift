//
//  WhatsNewTableViewController.swift
//  myUBC
//
//  Created by myUBC on 2021-02-22.
//

import UIKit

@MainActor
class WhatsNewTableViewController: UITableViewController {
    private let generatorNotice = UINotificationFeedbackGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
    }

    func setupTable() {
        // WhatsNewTableViewCell
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag
        tableView.insetsContentViewsToSafeArea = true
        tableView.estimatedRowHeight = 410

        tableView.register(UINib(nibName: WhatsNewTableViewCell.nib, bundle: nil), forCellReuseIdentifier: WhatsNewTableViewCell.nib)
    }

    @objc func dismissView() {
        generatorNotice.notificationOccurred(.success)
        dismiss(animated: true, completion: nil)
    }
}

extension WhatsNewTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WhatsNewTableViewCell.nib) as? WhatsNewTableViewCell else {
            return UITableViewCell()
        }
        cell.setupUI()
        cell.continueBtn.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        cell.selectionStyle = .none
        return cell
    }
}
