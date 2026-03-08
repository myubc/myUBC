//
//  LongSummaryCollectionViewCell.swift
//  myUBC
//
//  Created by myUBC on 2022-09-09.
//

import Lottie
import UIKit

class LongSummaryCollectionViewCell: UICollectionViewCell {
    static var nib: String {
        return "LongSummaryCollectionViewCell"
    }

    @IBOutlet var shadowView: UIView!
    @IBOutlet var baseView: UIView!
    @IBOutlet var loadingView: AnimationView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
        showLoadingView()
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
        loadingView.layer.cornerRadius = 12
        LandingCardShadowStyler.setup(baseView: baseView, shadowView: shadowView, cornerRadius: 12)
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
        LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
    }
}
