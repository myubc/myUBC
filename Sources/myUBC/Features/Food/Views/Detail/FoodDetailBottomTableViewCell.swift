//
//  FoodDetailBottomTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-10-18.
//

import UIKit

class FoodDetailBottomTableViewCell: UITableViewCell {
    weak var foodProtocol: FoodDetailProtocol?
    @IBOutlet var btn: UIButton!

    static var nib: String {
        return "FoodDetailBottomTableViewCell"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        btn.layer.cornerRadius = 8
    }

    @IBAction func didlearnMore(_ sender: Any) {
        foodProtocol?.didLearnMore()
    }
}
