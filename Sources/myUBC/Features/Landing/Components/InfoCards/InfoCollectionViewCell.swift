//
//  InfoCollectionViewCell.swift
//  myUBC
//
//  Created by myUBC on 2022-09-03.
//

import UIKit

class InfoCollectionViewCell: UICollectionViewCell {
    static var nib: String {
        return "InfoCollectionViewCell"
    }

    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
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

    func setup(for model: [CampusNotification]?) {
        guard let model = model else {
            title.attributedText =
                NSMutableAttributedString.setIconWithTitleString(isSuccess: false, isCaution: false, text: "N/A")
            subtitle.text = "N/A"
            LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
            return
        }
        guard !model.isEmpty else {
            title.attributedText =
                NSMutableAttributedString.setIconWithTitleString(isSuccess: true, isCaution: false, text: "All Good")
            subtitle.text = "No Campus-wide Anncoument at this time"
            LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
            return
        }
        title.attributedText = NSMutableAttributedString.setIconWithTitleString(
            isSuccess: false,
            isCaution: true,
            text: "\(model.count) Anncoument\(model.count > 1 ? "s" : "")"
        )
        subtitle.text = model.first?.title ?? ""
        LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
    }
}
