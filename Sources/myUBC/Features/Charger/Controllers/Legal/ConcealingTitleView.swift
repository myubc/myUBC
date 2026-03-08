//
//  ConcealingTitleView.swift
//  myUBC
//
//  Created by myUBC on 2020-02-26.
//

import UIKit

final class ConcealingTitleView: UIView {
    private let label = UILabel()
    private var contentOffset: CGFloat = 0 {
        didSet {
            label.frame.origin.y = titleVerticalPositionAdjusted(by: contentOffset)
        }
    }

    var text: String = "" {
        didSet {
            label.text = text
            label.textColor = UIColor.label
            label.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
            setNeedsLayout()
        }
    }

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if #available(iOS 11.0, *) {
            return super.sizeThatFits(size)
        } else {
            let height = (typedSuperview() as? UINavigationBar)?.bounds.height ?? 0.0
            let labelSize = label.sizeThatFits(CGSize(width: size.width, height: height))
            return CGSize(width: min(labelSize.width, size.width), height: height)
        }
    }

    private func layoutSubviews_10() {
        guard let navBar = typedSuperview() as? UINavigationBar else { return }
        let center = convert(navBar.center, from: navBar)
        let size = label.sizeThatFits(bounds.size)
        let x = max(bounds.minX, center.x - size.width * 0.5)
        let y: CGFloat

        if contentOffset == 0 {
            y = bounds.maxY
        } else {
            y = titleVerticalPositionAdjusted(by: contentOffset)
        }

        label.frame = CGRect(x: x, y: y, width: min(size.width, bounds.width), height: size.height)
    }

    private func layoutSubviews_11() {
        let size = label.sizeThatFits(bounds.size)
        let x: CGFloat
        let y: CGFloat

        x = bounds.midX - size.width * 0.5

        if contentOffset == 0 {
            y = bounds.maxY
        } else {
            y = titleVerticalPositionAdjusted(by: contentOffset)
        }

        label.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if #available(iOS 11.0, *) {
            layoutSubviews_11()
        } else {
            layoutSubviews_10()
        }
    }

    // MARK:

    /// Using the UIScrollViewDelegate it moves the inner UILabel to move up and down following the scroll offset.
    ///
    /// - Parameters:
    ///   - scrollView: The scroll-view object in which the scrolling occurred.
    ///   - threshold: The minimum distance that must be scrolled before the title view will begin scrolling up into view
    func scrollViewDidScroll(_ scrollView: UIScrollView, threshold: CGFloat = 0) {
        contentOffset = scrollView.contentOffset.y - threshold
    }

    // MARK: Private

    private func titleVerticalPositionAdjusted(by yOffset: CGFloat) -> CGFloat {
        let midY = bounds.midY - label.bounds.height * 0.5
        return max(bounds.maxY - yOffset, midY).rounded()
    }

    private func configure() {
        addSubview(label)
        clipsToBounds = true
        isUserInteractionEnabled = false
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
                self.sizeToFit()
            }
        }
    }
}

private extension UIView {
    func typedSuperview<T: UIView>() -> T? {
        var parent = superview

        while parent != nil {
            if let view = parent as? T {
                return view
            } else {
                parent = parent?.superview
            }
        }

        return nil
    }
}
