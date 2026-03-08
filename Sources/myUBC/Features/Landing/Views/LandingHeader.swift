//
//  LandingHeader.swift
//  myUBC
//
//  Created by myUBC on 2022-09-08.
//

import UIKit

class LandingHeader: UICollectionReusableView {
    @IBOutlet var todayLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    static var nib: String {
        return "LandingHeader"
    }

    @IBOutlet var bellBtn: MIBadgeButton!
    var action: (() -> Void)?
    private let noticeBanner = StatusBannerView()
    private var todayTopToSafeAreaConstraint: NSLayoutConstraint?
    private var todayTopToBannerConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        bellBtn.withAnimation = true
        todayLabel.accessibilityIdentifier = "landing.header.today"
        dateLabel.accessibilityIdentifier = "landing.header.date"
        bellBtn.accessibilityIdentifier = "landing.header.bell"
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM d"
        dateLabel.text = dateFormatterPrint.string(from: Date())
        setupNoticeBanner()
    }

    @objc func badgeCheck() {
        DispatchQueue.main.async {
            let num = ReminderStateStore.pendingReminderCount()
            self.bellBtn.badgeString = (num > 0) ? String(num) : ""
            self.bellBtn.badgeTextColor = .white
            self.bellBtn.accessibilityValue = (num > 0) ? String(num) : nil
        }
    }

    @IBAction func didTapSettings(_ sender: Any) {
        if let action = action {
            action()
        }
    }

    func configureStatusMessage(_ message: String?, style: StatusBannerStyle = .offline) {
        let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isVisible = !trimmed.isEmpty
        noticeBanner.isHidden = !isVisible

        if isVisible {
            noticeBanner.apply(message: trimmed, style: style)
        }

        todayTopToSafeAreaConstraint?.isActive = !isVisible
        todayTopToBannerConstraint?.isActive = isVisible
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func setupNoticeBanner() {
        noticeBanner.translatesAutoresizingMaskIntoConstraints = false
        noticeBanner.isUserInteractionEnabled = false
        noticeBanner.accessibilityIdentifier = "landing.header.notice"
        noticeBanner.isHidden = true
        addSubview(noticeBanner)

        todayTopToSafeAreaConstraint = todayLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40)
        todayTopToBannerConstraint = todayLabel.topAnchor.constraint(equalTo: noticeBanner.bottomAnchor, constant: 16)
        todayTopToSafeAreaConstraint?.isActive = true

        NSLayoutConstraint.activate([
            noticeBanner.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            noticeBanner.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            noticeBanner.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
}
