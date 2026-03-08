//
//  LandingSectionHeader.swift
//  myUBC
//
//  Created by myUBC on 2022-09-08.
//

import Foundation
import UIKit

class LandingSectionHeader: UICollectionReusableView {
    static var nib: String {
        return "LandingSectionHeader"
    }

    @IBOutlet var title: UILabel!
    @IBOutlet var button: UIButton!
    @IBOutlet var status: UIButton!

    var action: (() -> Void)?
    var errorActon: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    }

    func setup(hasError: Bool, action: (() -> Void)?, errorAction: (() -> Void)?) {
        if hasError {
            button.isEnabled = false
            status.isHidden = false
        } else {
            button.isEnabled = true
            status.isHidden = true
        }
        self.action = action
        errorActon = errorAction
    }

    @IBAction func didTapMore(_ sender: Any) {
        if let action = action {
            action()
        }
    }

    @IBAction func didTapError(_ sender: Any) {
        if let error = errorActon {
            error()
        }
    }
}
