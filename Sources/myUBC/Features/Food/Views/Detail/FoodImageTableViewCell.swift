//
//  FoodImageTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-10-18.
//

import UIKit

class FoodImageTableViewCell: UITableViewCell {
    @IBOutlet var foodImgView: UIImageView!

    static var nib: String {
        return "FoodImageTableViewCell"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        foodImgView.layer.cornerRadius = 8
    }

    func setupImage(url: String) {
        foodImgView.url(url)
    }
}
