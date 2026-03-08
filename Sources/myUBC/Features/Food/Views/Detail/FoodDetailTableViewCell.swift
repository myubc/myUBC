//
//  FoodDetailTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-10-01.
//

import UIKit

class FoodDetailTableViewCell: UITableViewCell {
    @IBOutlet var logo: UIImageView!

    @IBOutlet var stars: UIImageView!
    @IBOutlet var ratingText: UILabel!

    @IBOutlet var statusIcon: UIButton!
    @IBOutlet var statusShortLabel: UILabel!
    @IBOutlet var statusLongLabel: UILabel!

    @IBOutlet var carryoverIcon: UIButton!
    @IBOutlet var ubccardIcon: UIButton!
    @IBOutlet var mealplansIcon: UIButton!

    @IBOutlet var detailLabel: UILabel!
    @IBOutlet var baseView: UIView!
    @IBOutlet var view1: UIView!
    @IBOutlet var view2: UIView!
    @IBOutlet var view3: UIView!

    static var nib: String {
        return "FoodDetailTableViewCell"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        logo.layer.cornerRadius = 8
        baseView.layer.cornerRadius = 8
        view1.layer.cornerRadius = 8
        view2.layer.cornerRadius = 8
        view3.layer.cornerRadius = 8
    }

    func setupStatus(isOpen: Bool, fullStatus: String) {
        statusIcon.tintColor = isOpen ? #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1) : #colorLiteral(red: 0.8588235294, green: 0.3607843137, blue: 0, alpha: 1)
        let image = isOpen ?
            UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "exclamationmark.circle.fill")
        statusIcon.setImage(image, for: .normal)
        statusLongLabel.text = fullStatus
        statusShortLabel.text = isOpen ? "Open" : "Closed"
    }

    func setupLogo(src: String, url: String, slug: String) {
        logo.image = FoodLogoResolver.image(for: src, url: url, slug: slug)
    }

    func setupRating(rating: Int) {
        guard rating > 0, rating <= 5 else {
            return
        }
        stars.image = UIImage(named: "\(rating)")
        ratingText.text = "Rating \(rating)/5"
    }

    func setupCarry(isOn: Bool) {
        carryoverIcon.tintColor = isOn ? #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1) : #colorLiteral(red: 0.8588235294, green: 0.3607843137, blue: 0, alpha: 1)
        let image = isOn ?
            UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "exclamationmark.circle.fill")
        carryoverIcon.setImage(image, for: .normal)
    }

    func setupCard(isOn: Bool) {
        ubccardIcon.tintColor = isOn ? #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1) : #colorLiteral(red: 0.8588235294, green: 0.3607843137, blue: 0, alpha: 1)
        let image = isOn ?
            UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "exclamationmark.circle.fill")
        ubccardIcon.setImage(image, for: .normal)
    }

    func setupMeal(isOn: Bool) {
        mealplansIcon.tintColor = isOn ? #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1) : #colorLiteral(red: 0.8588235294, green: 0.3607843137, blue: 0, alpha: 1)
        let image = isOn ?
            UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "exclamationmark.circle.fill")
        mealplansIcon.setImage(image, for: .normal)
    }

    func setupDetail(detail: String) {
        detailLabel.text = detail
    }
}
