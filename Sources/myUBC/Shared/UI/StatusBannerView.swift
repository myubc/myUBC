//
//  StatusBannerView.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import UIKit

enum StatusBannerStyle {
    case stale
    case offline
    case info

    var backgroundColor: UIColor {
        switch self {
        case .stale:
            return UIColor.systemYellow.withAlphaComponent(0.18)
        case .offline:
            return UIColor.systemRed.withAlphaComponent(0.18)
        case .info:
            return UIColor.systemBlue.withAlphaComponent(0.18)
        }
    }

    var textColor: UIColor {
        switch self {
        case .stale:
            return UIColor.systemOrange
        case .offline:
            return UIColor.systemRed
        case .info:
            return UIColor.systemBlue
        }
    }
}

final class StatusBannerView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 10
        layer.masksToBounds = true
        isAccessibilityElement = true
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.accessibilityIdentifier = "status-banner.label"
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }

    func apply(message: String, style: StatusBannerStyle) {
        backgroundColor = style.backgroundColor
        label.textColor = style.textColor
        label.text = message
        accessibilityLabel = message
        invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.preferredMaxLayoutWidth = max(0, bounds.width - 24)
    }

    func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        bounds.size.width = width
        label.preferredMaxLayoutWidth = max(0, width - 24)
        setNeedsLayout()
        layoutIfNeeded()
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        return ceil(systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height)
    }
}

@MainActor
extension UIViewController {
    private var inlineStatusBannerTag: Int {
        917_331
    }

    func showStatusBanner(message: String, style: StatusBannerStyle) {
        // Keep network freshness messaging non-blocking by showing it as
        // subtle footer text in table-based screens.
        if let tableController = self as? UITableViewController {
            tableController.setTableFooterStatusMessage(message)
            return
        }

        hideStatusBanner()
        let banner = StatusBannerView()
        banner.tag = inlineStatusBannerTag
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.isUserInteractionEnabled = false
        banner.apply(message: message, style: style)
        view.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }

    func hideStatusBanner() {
        if let tableController = self as? UITableViewController {
            tableController.setTableFooterStatusMessage(nil)
            return
        }
        view.viewWithTag(inlineStatusBannerTag)?.removeFromSuperview()
    }
}

@MainActor
extension UITableViewController {
    func setTableFooterStatusMessage(_ message: String?) {
        guard let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            tableView.tableFooterView = UIView(frame: .zero)
            return
        }

        let footerHeight: CGFloat = 36
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: footerHeight))
        let label = UILabel(frame: container.bounds.insetBy(dx: 12, dy: 8))
        label.text = message
        label.textAlignment = .center
        label.textColor = .placeholderText
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.numberOfLines = 1
        container.addSubview(label)
        tableView.tableFooterView = container
    }
}
