//
//  ErrorTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-02-10.
//

import UIKit

class ErrorTableViewCell: UITableViewCell {
    var fallbackURL: String?
    weak var detailView: ChargerDetailViewController?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        // Initialization code
    }

    @IBAction func didFallBack(_ sender: Any) {
        detailView?.fallback(for: fallbackURL ?? "")
    }
}
