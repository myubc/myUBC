//
//  DeviceDetailCell.swift
//  myUBC
//
//  Created by myUBC on 2020-01-27.
//

import CoreMotion
import UIKit

class DeviceDetailCell: UITableViewCell {
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var shadowView: UIView!
    @IBOutlet var baseView: UIView!

    private let motionManager = CMMotionManager()
    weak var deviceProtocol: DeviceProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        baseView.layer.cornerRadius = 12
        shadowView.layer.cornerRadius = 12
    }

    /* func setupShadow() {
         return
         var width: CGFloat = 0.0, height: CGFloat = 5.0
                 if motionManager.isDeviceMotionAvailable {
                     motionManager.deviceMotionUpdateInterval = 0.02
                     motionManager.startDeviceMotionUpdates(to: .main, withHandler: { (motion, error) in
                         if let motion = motion {
                             let pitch = motion.attitude.pitch * 10 // x-axis
                             let roll = motion.attitude.roll * 10 // y-axis
                             width = CGFloat(roll)
                             height = CGFloat(pitch)
                         }
                     })
                 }

                let shadowPath = UIBezierPath(roundedRect:
                    shadowView.bounds, cornerRadius: 14.0)
                shadowView.layer.masksToBounds = false
                shadowView.layer.shadowRadius = 8.0
                shadowView.layer.shadowColor = UIColor.darkGray.cgColor
                shadowView.layer.shadowOffset = CGSize(width: width, height: height)
                shadowView.layer.shadowOpacity = 0.35
                shadowView.layer.shadowPath = shadowPath.cgPath
     } */

    func setup(title: String, items: [EquipmentStatus]) {
        selectionStyle = .none

        for view in stackView.subviews {
            view.removeFromSuperview()
        }

        if let view = DeviceTitleView.instanceFromNib() as? DeviceTitleView {
            view.title.text = title
            stackView.addArrangedSubview(view)
        }

        for item in items {
            if let view = StatusContentView.instanceFromNib() as? StatusContentView {
                view.icon.isHidden = false
                // view.separator.isHidden = true
                view.icon.image = (item.isAvailable) ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "exclamationmark.circle.fill")
                view.icon.tintColor = (item.isAvailable) ? #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1) : #colorLiteral(red: 0.8588235294, green: 0.3607843137, blue: 0, alpha: 1)
                view.pushBtn.isEnabled = item.isAvailable
                view.pushBtn.addTarget(self, action: #selector(pushCheckoutView), for: .touchUpInside)
                view.statusLabel.textColor = (item.isAvailable) ? .label : .secondaryLabel
                view.refLabel.textColor = (item.isAvailable) ? .secondaryLabel : .quaternaryLabel
                view.nextArrow.isHidden = !(item.isAvailable)
                if let ref = item.referenceNo?.uppercased() {
                    view.refLabel.text = "Reference Number: " + ref
                }
                if let date = item.date {
                    if !item.note.isEmpty {
                        // if known reason with date
                        view.statusLabel.text = item.note + " on " + formatDate(date: date)
                    } else {
                        let content = (item.isAvailable) ? "Returned on " : "On Loan, Due on "
                        view.statusLabel.text = content + formatDate(date: date)
                    }
                } else {
                    if item.note.isEmpty, !item.isAvailable {
                        // unknown reason with no dates available
                        view.statusLabel.text = "Not Available"
                    } else if item.note.isEmpty, item.isAvailable {
                        view.statusLabel.text = "Available"
                    } else if !item.note.isEmpty {
                        view.statusLabel.text = item.note
                    }
                }
                stackView.addArrangedSubview(view)
            }
        }
    }

    @objc func pushCheckoutView() {
        deviceProtocol?.pushCheckoutView()
    }

    func formatDate(date: Date) -> String {
        var firstPart = ""
        var secondPart = ""

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        if
            !dateFormatter.string(from: date).contains("Today") &&
            !dateFormatter.string(from: date).contains("Yesterday") &&
            !dateFormatter.string(from: date).contains("Tomorrow")
        {
            let customFormatter = DateFormatter()
            customFormatter.dateFormat = "MMM d"
            firstPart = customFormatter.string(from: date)
        } else {
            firstPart = dateFormatter.string(from: date)
        }

        if timeFormatter.string(from: date).contains("12:00") || timeFormatter.string(from: date).contains("00:00") {
            secondPart = ""
        } else {
            secondPart = " at " + timeFormatter.string(from: date)
        }

        return firstPart + secondPart
    }
}
