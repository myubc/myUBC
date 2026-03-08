//
//  ParkingStatusCollectionViewCell.swift
//  myUBC
//
//  Created by myUBC on 2022-09-03.
//

import UIKit

class ParkingStatusCollectionViewCell: UICollectionViewCell {
    static var nib: String {
        return "ParkingStatusCollectionViewCell"
    }

    @IBOutlet var parkadeName: UILabel!
    @IBOutlet var statusImg: UIImageView!
    @IBOutlet var statusBg: UIView!

    @IBOutlet var baseView: UIView!
    @IBOutlet var shadowView: UIView!

    private let parkingStatusLabel = UILabel()
    private let evStatusLabel = UILabel()
    private var didSetupStatusLabels = false

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
        setupStatusLabelsIfNeeded()
    }

    func setup(for parkade: ParkingAnnotation) {
        setupStatusLabelsIfNeeded()

        let primaryStatus = parkade.status.first ?? .unkown
        statusImg.tintColor = statusColor(primaryStatus)
        statusImg.image = primaryStatus == .good ?
            UIImage(systemName: "checkmark.circle.fill") :
            UIImage(systemName: "exclamationmark.triangle.fill")

        parkadeName.text = (parkade.lotName == .unknown) ? "N/A" : parkade.lotName.rawValue
        LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
    }

    private func setupStatusLabelsIfNeeded() {
        guard !didSetupStatusLabels else { return }
        didSetupStatusLabels = true

        for label in [parkingStatusLabel, evStatusLabel] {
            label.font = .systemFont(ofSize: 12, weight: .regular)
            label.textAlignment = .center
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
        }

        let stack = UIStackView(arrangedSubviews: [parkingStatusLabel, evStatusLabel])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        statusBg.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: statusBg.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: statusBg.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: statusBg.topAnchor),
            stack.bottomAnchor.constraint(equalTo: statusBg.bottomAnchor)
        ])
    }

    private func statusText(_ status: ParkingStatus) -> String {
        switch status {
        case .good:
            return "Good"
        case .limited:
            return "Limited"
        case .full:
            return "Full"
        case .unkown:
            return "N/A"
        }
    }

    private func statusColor(_ status: ParkingStatus) -> UIColor {
        switch status {
        case .good:
            return #colorLiteral(red: 0.203841567, green: 0.7802445292, blue: 0.3491154611, alpha: 1)
        case .limited:
            return #colorLiteral(red: 0.9997915626, green: 0.5527015924, blue: 0.1568311453, alpha: 1)
        case .full:
            return #colorLiteral(red: 0.6754626632, green: 0, blue: 0, alpha: 1)
        case .unkown:
            return .secondaryLabel
        }
    }
}
