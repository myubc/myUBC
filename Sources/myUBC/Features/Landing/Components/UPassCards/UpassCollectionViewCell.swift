//
//  UpassCollectionViewCell.swift
//  myUBC
//
//  Created by myUBC on 2022-09-03.
//

import UIKit

class UpassCollectionViewCell: UICollectionViewCell {
    static var nib: String {
        return "UpassCollectionViewCell"
    }

    @IBOutlet var leftDays: UILabel!
    @IBOutlet var reminderStatusLabel: UILabel!
    @IBOutlet var baseView: UIView!
    @IBOutlet var shadowView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
        reminderLabelDefault()
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

    func setup() {
        let dateComponents = NSDateComponents()
        dateComponents.year = Date().get(.year)
        dateComponents.month = Date().get(.month)
        dateComponents.day = 16

        let calendar = NSCalendar.current
        let date1 = calendar.date(from: dateComponents as DateComponents) ?? Date()
        let diffInDays = max(0, Calendar.current.dateComponents([.day], from: Date(), to: date1).day ?? 0)

        let nextMonth = Date().get(.month) == 12 ? 1 : Date().get(.month) + 1
        let dateComponents2 = NSDateComponents()
        dateComponents2.year = Date().get(.year)
        dateComponents2.month = nextMonth
        dateComponents2.day = 16
        let date2 = calendar.date(from: dateComponents2 as DateComponents) ?? Date()
        let diffInDays2 = max(Calendar.current.dateComponents([.day], from: Date(), to: date2).day ?? 0, 0)

        if diffInDays == 0 {
            leftDays.text = "\(diffInDays2) Day\(diffInDays2 > 1 ? "s" : "") Left"
        } else {
            leftDays.text = "\(diffInDays) Day\(diffInDays2 > 1 ? "s" : "") Left"
        }
        reminderLabel()
        LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
    }

    func reminderLabelDefault() {
        reminderStatusLabel.attributedText =
            NSMutableAttributedString.setIconWithSmallLabelString(
                isSuccess: false,
                isCaution: false,
                text: "Reminder Not Set Up"
            )
    }

    func reminderLabel() {
        let text = ReminderStateStore.hasPendingUpassReminder() ? "Reminder On" : "Reminder Not Set Up"
        let isSuccess = ReminderStateStore.hasPendingUpassReminder()
        reminderStatusLabel.attributedText = NSMutableAttributedString.setIconWithSmallLabelString(
            isSuccess: isSuccess,
            isCaution: false,
            text: text
        )
        LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
    }
}
