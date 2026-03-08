//
//  ParkingAnnotationCallout.swift
//  myUBC
//
//  Created by myUBC on 2022-04-22.
//

import Foundation
import Lottie
import UIKit

class ParkingAnnotationCallout: UIView {
    var parkingLotStatus: ParkingStatus = .good {
        didSet {
            updateStatus()
        }
    }

    var evStatus: ParkingStatus = .good {
        didSet {
            updateStatus()
        }
    }

    @IBOutlet var parkadeName: UILabel!

    @IBOutlet private var parkingLabel: UILabel?
    @IBOutlet private var evLabel: UILabel?

    @IBOutlet private var parkingImage: UIImageView?
    @IBOutlet private var evImage: UIImageView?
    @IBOutlet var divider: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        divider.layer.cornerRadius = 4
        // Initialization code
        // parkingLabel?.isHidden = true
        // evLabel?.isHidden = true
    }

    private func updateStatus() {
        set(status: parkingLotStatus, forLabel: parkingLabel, withIcon: parkingImage)
        set(status: evStatus, forLabel: evLabel, withIcon: evImage)
    }

    private func set(status: ParkingStatus, forLabel label: UILabel?, withIcon icon: UIImageView?) {
        guard let label = label, let icon = icon else { return }
        switch status {
        case .good:
            label.text = "Good"
            icon.image = UIImage(systemName: "checkmark.circle.fill")
            icon.tintColor = #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1)
        case .limited:
            label.text = "Limited"
            icon.image = UIImage(systemName: "exclamationmark.circle.fill")
            icon.tintColor = #colorLiteral(red: 0.8681644797, green: 0.6292878985, blue: 0.1429967284, alpha: 1)
        case .full:
            label.text = "Full"
            icon.image = UIImage(systemName: "exclamationmark.circle.fill")
            icon.tintColor = #colorLiteral(red: 0.6754626632, green: 0, blue: 0, alpha: 1)
        case .unkown:
            label.text = "N/A"
            icon.image = UIImage(systemName: "exclamationmark.circle.fill")
            icon.tintColor = UIColor.label
        }
    }
}
