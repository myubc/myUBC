//
//  CheckoutTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-02-13.
//

import UIKit

class CheckoutTableViewCell: UITableViewCell {
    @IBOutlet var backgroundBaseView: UIView!
    @IBOutlet var policyBtn: UIButton!
    var timerProtocol: CheckoutProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundBaseView.layer.cornerRadius = 8
        // Initialization code
    }

    @IBAction func didCheckPolicy(_ sender: Any) {
        timerProtocol?.showLoanPolicy()
    }
}
