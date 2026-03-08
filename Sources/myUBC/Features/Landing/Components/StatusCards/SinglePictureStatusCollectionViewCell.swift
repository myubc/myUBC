//
//  SinglePictureStatusCollectionViewCell.swift
//  myUBC
//
//  Created by myUBC on 2022-09-03.
//

import UIKit

class SinglePictureStatusCollectionViewCell: UICollectionViewCell {
    static var nib: String {
        return "SinglePictureStatusCollectionViewCell"
    }

    @IBOutlet var logo: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var status: UILabel!

    @IBOutlet var top: NSLayoutConstraint!
    @IBOutlet var left: NSLayoutConstraint!
    @IBOutlet var right: NSLayoutConstraint!
    @IBOutlet var bottom: NSLayoutConstraint!

    @IBOutlet var baseView: UIView!
    @IBOutlet var shadowView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    override var isHighlighted: Bool {
        didSet {
            shrink(down: isHighlighted)
        }
    }

    func shrink(down: Bool) {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction]) {
            if down {
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } else {
                self.transform = .identity
            }
        }
    }

    func setupViews() {
        layer.masksToBounds = false
        LandingCardShadowStyler.setup(baseView: baseView, shadowView: shadowView, cornerRadius: 12)
    }

    func setup(isAvailable: Bool, image: UIImage, title: String, forFood: Bool) {
        // padding is used to differentiate charger view and food view
        let statusLabel = isAvailable ? (forFood ? "Open" : "Available") : (forFood ? "Closed" : "Unavailable")
        let string = NSMutableAttributedString.setIconWithSmallLabelString(
            isSuccess: isAvailable,
            isCaution: !isAvailable,
            text: statusLabel
        )
        self.title.text = title
        logo.image = image
        status.attributedText = string
        LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
    }
}
