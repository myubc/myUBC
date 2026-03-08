//
//  TitleTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-12.
//

import Lottie
import UIKit

class TitleTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var warningLabel: AnimationView!
    @IBOutlet var lastUpdated: UILabel!
    @IBOutlet var refreshBtn: UIButton!
    @IBOutlet var baseView: UIView!
    @IBOutlet var RefreshWrapper: UIView!
    @IBOutlet var loadingView: AnimationView!

    var warnings: [CampusNotification] = [] {
        didSet {
            setup()
        }
    }

    var lastUpdatedDate: Date?
    var showsTimestampLabel: Bool = true

    var showError: Bool = false

    func setup() {
        baseView.layer.cornerRadius = 8
        RefreshWrapper.layer.cornerRadius = 8
        loadingView.layer.cornerRadius = 8
        loadingView.layer.masksToBounds = true
        loadingView.isHidden = true
        if warnings.isEmpty, !showError {
            titleLabel.text = NSLocalizedString("info.none", comment: "No campus notifications title")
        } else {
            titleLabel.text = showError
                ? NSLocalizedString("alert.network.title", comment: "Network error title")
                : NSLocalizedString("info.active", comment: "Campus notification active title")
            // warningLabel.contentMode = .scaleAspectFit
            warningLabel.loopMode = .playOnce
        }
        lastUpdated.text = showsTimestampLabel ? getTimestamp() : ""
        warningLabel.animation = warnings.isEmpty && !showError ? Animation.named("ok") : Animation.named("warning")
        // Initialization code
        warningLabel.layoutIfNeeded()
        warningLabel.play()
    }

    func showLoadingView() {
        loadingView.alpha = 0
        loadingView.isHidden = false
        loadingView.animation = Animation.named("loading")
        loadingView.loopMode = .loop
        loadingView.play()
        UIView.animate(withDuration: 1, animations: {
            self.loadingView.alpha = 0.9
        })
    }

    private func getTimestamp() -> String {
        guard let date = lastUpdatedDate else { return "" }
        if let message = CacheBanner.lastUpdatedMessage(from: date) {
            return message
        }
        return ""
    }
}
