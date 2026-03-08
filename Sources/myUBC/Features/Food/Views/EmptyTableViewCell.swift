//
//  EmptyTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-26.
//

import Lottie
import UIKit

class EmptyTableViewCell: UITableViewCell {
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var webapgeBtn: UIButton!
    @IBOutlet var loadingView: AnimationView!

    static var nib: String {
        return Constants.foodPlaceholderIdentifier
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
        webapgeBtn.layer.cornerRadius = 8
        loadingView.layer.cornerRadius = 8
    }

    func setup(isError: Bool) {
        if isError {
            title.text = "Network Error"
            subtitle.text = "Something went wrong while connecting to UBC web services"
            webapgeBtn.isHidden = false
        } else {
            title.text = "Nothing Here"
            subtitle.text = "All UBC food services are closed right now, come back later!"
            webapgeBtn.isHidden = true
        }
    }

    func showLoading() {
        loadingView.alpha = 0
        loadingView.animation = Animation.named("loading")
        loadingView.loopMode = .loop
        loadingView.play()
        loadingView.isHidden = false
        UIView.animate(withDuration: 1, animations: {
            self.loadingView.alpha = 0.7
        })
    }
}
