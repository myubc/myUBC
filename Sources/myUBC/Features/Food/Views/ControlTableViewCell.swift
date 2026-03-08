//
//  ControlTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-26.
//

import UIKit

class ControlTableViewCell: UITableViewCell {
    @IBOutlet var segControl: UISegmentedControl!

    static var nib: String {
        return Constants.foodTableIdentifier
    }

    weak var controller: FoodTableViewControllerProtocol?

    @IBAction func didSwitch(_ sender: Any) {
        controller?.filter(toShowAll: segControl.selectedSegmentIndex == 0)
    }
}
