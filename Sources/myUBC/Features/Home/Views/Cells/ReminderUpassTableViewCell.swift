//
//  ReminderUpassTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-28.
//

import Lottie
import UIKit

class ReminderUpassTableViewCell: UITableViewCell {
    @IBOutlet var baseView: UIView!
    @IBOutlet var statusIcon: AnimationView!
    @IBOutlet var title: UILabel!
    @IBOutlet var subTitle: UILabel!
    @IBOutlet var showUpassPage: UIButton!

    static var nib: String {
        return "ReminderUpassTableViewCell"
    }

    var isOn = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
        baseView.layer.cornerRadius = 8
        showUpassPage.layer.cornerRadius = 8
        getStatus()
    }

    func getStatus() {
        isOn = ReminderStateStore.hasPendingUpassReminder()
        setup()
    }

    private func setup() {
        showUpassPage.isHidden = isOn
        statusIcon.animation = isOn ? Animation.named("ok") : Animation.named("warning")
        title.text = isOn ? "Reminder Active" : "Reminder Not Set Up"
        subTitle.text = isOn ? "Your monthly U-Pass renewal reminder is active." : "Open U-Pass Renewal to set up a monthly reminder."
        statusIcon.loopMode = .playOnce
        statusIcon.play()
    }
}
