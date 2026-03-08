//
//  SummaryCollectionViewCell.swift
//  myUBC
//
//  Created by myUBC on 2022-09-03.
//

import CoreImage
import UIKit

class SummaryCollectionViewCell: UICollectionViewCell {
    static var nib: String {
        return "SummaryCollectionViewCell"
    }

    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var baseView: UIView!
    @IBOutlet var shadowView: UIView!

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
    }

    func setup(type: SummaryType, isAvailable: Bool, count: Int) {
        switch type {
        case .food:
            let label = (count == 0) ? "No Places" : "\(count) Place\(count > 1 ? "s" : "")"
            title.attributedText = NSMutableAttributedString.setIconWithTitleString(
                isSuccess: isAvailable,
                isCaution: false,
                text: label
            )
            subtitle.text = "Opening Now"
            subtitle.isHidden = false
            iconView.image = UIImage(named: "foodAll")
        case .calendar:
            let label = (count == 0) ? "No Events Today" : "\(count) Event\(count > 1 ? "s" : "") Today"
            let attr = [NSAttributedString.Key.font:
                UIFont.systemFont(ofSize: 22.0)]
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = UIImage(systemName: "calendar")?.withTintColor(.systemRed)
            let image1String = NSAttributedString(attachment: image1Attachment)
            let fullString = NSMutableAttributedString(string: "", attributes: attr)
            fullString.append(image1String)
            fullString.append(NSMutableAttributedString(string: " ", attributes: attr))
            title.attributedText =
                NSMutableAttributedString.setCustomIconWithTitleString(icon: fullString, text: label)
            subtitle.isHidden = true
            iconView.image = UIImage(named: "calendar")
        case .parkade:
            let attr = [NSAttributedString.Key.font:
                UIFont.systemFont(ofSize: 22.0)]
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = UIImage(systemName: "car.fill")?.withTintColor(
                isAvailable ? UIColor.systemGreen :
                    UIColor.systemOrange
            )
            let image1String = NSAttributedString(attachment: image1Attachment)
            let fullString = NSMutableAttributedString(string: "", attributes: attr)
            fullString.append(image1String)
            fullString.append(NSMutableAttributedString(string: " ", attributes: attr))
            title.attributedText =
                NSMutableAttributedString.setCustomIconWithTitleString(
                    icon: fullString,
                    text: isAvailable ? "\(count) Parkade\(count > 1 ? "s" : "") Available" : "No Parkade Available"
                )
            subtitle.isHidden = true
            iconView.image = UIImage(named: "parking-cover")
        }
        LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
    }
}

enum SummaryType {
    case parkade, calendar, food
}

enum LandingCardShadowStyler {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    static func setup(baseView: UIView, shadowView: UIView, cornerRadius: CGFloat = 12) {
        baseView.layer.cornerRadius = cornerRadius
        baseView.layer.masksToBounds = true

        shadowView.layer.masksToBounds = false
        shadowView.layer.cornerRadius = cornerRadius
        shadowView.layer.shadowRadius = 12
        shadowView.layer.shadowOpacity = 0.22
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 8)
        shadowView.layer.shadowColor = UIColor.lightGray.cgColor
    }

    static func refreshShadowColor(from contentView: UIView, to shadowView: UIView) {
        contentView.layoutIfNeeded()
        let size = contentView.bounds.size
        guard size.width > 1, size.height > 1 else { return }

        let targetSize = CGSize(
            width: min(max(size.width * 0.18, 28), 72),
            height: min(max(size.height * 0.18, 28), 72)
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let image = renderer.image { context in
            context.cgContext.scaleBy(
                x: targetSize.width / size.width,
                y: targetSize.height / size.height
            )
            contentView.layer.render(in: context.cgContext)
        }

        guard let cgImage = image.cgImage else { return }
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIAreaAverage") else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        guard let output = filter.outputImage else { return }

        var bitmap = [UInt8](repeating: 0, count: 4)
        Self.ciContext.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let sampled = UIColor(
            red: CGFloat(bitmap[0]) / 255.0,
            green: CGFloat(bitmap[1]) / 255.0,
            blue: CGFloat(bitmap[2]) / 255.0,
            alpha: 1
        )
        shadowView.layer.shadowColor = tunedGlowColor(from: sampled).cgColor
    }

    private static func tunedGlowColor(from color: UIColor) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return UIColor.lightGray
        }

        if saturation < 0.08 {
            return UIColor.lightGray.withAlphaComponent(0.9)
        }

        let tunedSaturation = min(max(saturation * 1.35, 0.34), 0.92)
        let tunedBrightness = min(max(brightness + 0.22, 0.58), 0.95)
        return UIColor(hue: hue, saturation: tunedSaturation, brightness: tunedBrightness, alpha: 0.95)
    }
}
