//
//  CalendarErrorTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2021-02-03.
//

import Lottie
import UIKit

class CalendarErrorTableViewCell: UITableViewCell {
    @IBOutlet var animationView: AnimationView!
    @IBOutlet var baseView: UIView!
    @IBOutlet var sourceBtn: UIButton!

    static var nib: String {
        return "CalendarErrorTableViewCell"
    }

    var calendarProtocol: CalendarProtocols?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        baseView.layer.cornerRadius = 8
        sourceBtn.layer.cornerRadius = 8
        baseView.layer.masksToBounds = false
        baseView.layer.shadowColor = UIColor.darkGray.cgColor
        baseView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        baseView.layer.shadowRadius = 15.0
        baseView.layer.shadowOpacity = 0.4
    }

    func setup() {
        animationView.loopMode = .playOnce
        animationView.animation = Animation.named("warning")
        animationView.layoutIfNeeded()
        animationView.play()
    }

    @IBAction func didTapSource(_ sender: Any) {
        calendarProtocol?.showDeadLink()
    }
}
