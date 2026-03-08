//
//  FoodTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-26.
//

import Lottie
import UIKit

class FoodTableViewCell: UITableViewCell {
    @IBOutlet var name: UILabel!
    @IBOutlet var today: UILabel!
    @IBOutlet var hours: UILabel!
    @IBOutlet var location: UILabel!
    @IBOutlet var statusIcon: UIButton!

    @IBOutlet var logo: UIImageView!
    @IBOutlet var baseView: UIView!
    @IBOutlet var shadowView: UIView!

    @IBOutlet var loadingView: AnimationView!

    static var nib: String {
        return Constants.foodViewIdentifier
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        loadingView.layer.cornerRadius = 8
        baseView.layer.cornerRadius = 8
        shadowView.layer.cornerRadius = 8
        logo.layer.cornerRadius = 8
        setupShadow()
    }

    func setupShadow() {
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowRadius = 8.0
        shadowView.layer.shadowColor = UIColor.darkGray.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
        shadowView.layer.shadowOpacity = 0.2
    }

    func setup(model: FoodLocation) {
        loadingView.isHidden = true
        name.text = model.name
        today.text = (model.isOpen) ? "Open" : "Closed"
        hours.text = model.statusText

        logo.image = FoodLogoResolver.image(for: model.name, url: model.url, slug: model.slug)

        let normalizedAddress = model.address
            .replacingOccurrences(of: "\\n", with: ", ")
            .replacingOccurrences(of: "\n", with: ", ")
        if normalizedAddress.isEmpty {
            location.text = nil
            location.isHidden = true
        } else {
            location.text = normalizedAddress
            location.isHidden = false
        }

        statusIcon.tintColor = (model.isOpen) ? #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1) : #colorLiteral(red: 0.8588235294, green: 0.3607843137, blue: 0, alpha: 1)
        statusIcon.setImage(
            model.isOpen ?
                UIImage(systemName: Constants.foodOpenIcon) :
                UIImage(systemName: Constants.foodClosedIcon),
            for: .normal
        )
    }

    func showLoadingView() {
        loadingView.alpha = 0
        loadingView.animation = Animation.named("loading")
        loadingView.loopMode = .loop
        loadingView.play()
        loadingView.isHidden = false
        UIView.animate(withDuration: 1, animations: {
            self.loadingView.alpha = 0.9
        })
    }

    private func convertHours(from: Int) -> Int {
        // The weekday units are the numbers 1 through N
        // (where for the Gregorian calendar N=7 and 1 is Sunday).
        // while array index is from 0 (monday) to 6 (sunday)
        return (from - 2 >= 0) ? from - 2 : 6
    }
}
