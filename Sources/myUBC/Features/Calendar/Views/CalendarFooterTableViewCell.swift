//
//  CalendarFooterTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2021-01-31.
//

import UIKit

class CalendarFooterTableViewCell: UITableViewCell {
    @IBOutlet var sourceBtn: UIButton!
    var parent: CalendarProtocols?

    static var nib: String {
        return "CalendarFooterTableViewCell"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        sourceBtn.layer.cornerRadius = 8
    }

    @IBAction func didTapBtn(_ sender: Any) {
        if let parentProtocol = parent {
            parentProtocol.showSourcePopUp()
        }
    }
}
