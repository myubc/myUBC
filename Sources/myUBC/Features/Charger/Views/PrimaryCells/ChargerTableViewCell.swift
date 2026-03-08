//
//  ChargerTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-01-21.
//

import UIKit

class ChargerTableViewCell: UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var location: UILabel!
    @IBOutlet var contentImg: UIImageView!

    @IBOutlet var baseView: UIView!
    @IBOutlet var shadowView: UIView!

    @IBOutlet var loadingBaseView: UIView!
    @IBOutlet var statusIconBaseView: UIView!
    @IBOutlet var statusIcon: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        baseView.layer.cornerRadius = 8
        baseView.layer.masksToBounds = true
        shadowView.layer.cornerRadius = 8
    }
}
