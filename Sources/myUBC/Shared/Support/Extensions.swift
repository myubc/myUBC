//
//  Extensions.swift
//  myUBC
//
//  Created by myUBC on 2020-01-20.
//

import Foundation
import UIKit

enum FoodLogoResolver {
    private static let directAliases: [String: String] = [
        "avenue c store neville scarfe building": "Avenue C Store",
        "hero coffee market": "Hero",
        "hero harvest": "Harvest",
        "harvest market": "Harvest",
        "sage catering and campus delivery": "Sage",
        "open kitchen": "Open Kitchen",
        "pacific poke life": "Pacific Poke Life",
        "starbucks kaiser": "Starbucks Fred Kaiser",
        "stir it up cafe": "Stir it Up",
        "tim hortons q əlɬaləməcən leləm orca house": "Tim Hortons Orca House",
        "tim hortons orca house": "Tim Hortons Orca House",
        "triple os": "Triple Os"
    ]

    private static let fallbackAssets: [String] = [
        "Avenue C Store",
        "Bento Sushi",
        "Booster Juice Life",
        "Feast",
        "Fooood",
        "Fooood 2.0",
        "Gage Market",
        "Gather",
        "Harvest",
        "Hero",
        "Hubbards",
        "Ideas Lunch & Wine Bar",
        "Ike's",
        "Law Cafe",
        "Magda's",
        "Mercante",
        "Neville's",
        "Open Kitchen",
        "Pacific Poke",
        "Pacific Poke Life",
        "Perugia",
        "Sage",
        "Sauder Exchange",
        "Scholar's Catering",
        "Starbucks Bookstore",
        "Starbucks Fred Kaiser",
        "Starbucks Life",
        "Stir it Up",
        "Subway Life",
        "The Loop",
        "The Point",
        "Tim Hortons David Lam",
        "Tim Hortons Forestry",
        "Tim Hortons Orca House",
        "Triple Os"
    ]

    private static let slugNameCandidates: [String: [String]] = {
        var map: [String: Set<String>] = [:]

        for item in FoodCatalog.load() {
            guard let slug = slug(from: item.url) else { continue }
            map[slug, default: []].insert(item.spaceTitle)
        }

        for place in FoodPlaceCatalog.loadDefaults() {
            if let slug = slug(from: place.url) {
                map[slug, default: []].insert(place.displayName)
            }
            map[normalizeSlug(place.id), default: []].insert(place.displayName)
        }

        return map.mapValues { Array($0) }
    }()

    private static let allCandidates: [String] = Array(Set(FoodCatalog.load().map(\.spaceTitle) + fallbackAssets))

    static func image(for displayName: String, url: String = "", slug: String = "") -> UIImage? {
        if let direct = UIImage(named: displayName) {
            return direct
        }

        if
            let slugMatch = slugCandidate(from: slug, url: url),
            let names = slugNameCandidates[slugMatch]
        {
            for name in names where UIImage(named: name) != nil {
                return UIImage(named: name)
            }
        }

        let normalizedName = normalize(displayName)
        if let alias = directAliases[normalizedName], let image = UIImage(named: alias) {
            return image
        }

        var bestMatch: String?
        var bestScore = 0

        for candidate in allCandidates {
            guard UIImage(named: candidate) != nil else { continue }
            let normalizedCandidate = normalize(candidate)
            if normalizedCandidate == normalizedName {
                return UIImage(named: candidate)
            }

            if normalizedName.contains(normalizedCandidate) || normalizedCandidate.contains(normalizedName) {
                let score = min(normalizedName.count, normalizedCandidate.count)
                if score > bestScore {
                    bestScore = score
                    bestMatch = candidate
                }
            }
        }

        if let bestMatch {
            return UIImage(named: bestMatch)
        }

        return UIImage(named: "default")
    }

    private static func slugCandidate(from slug: String, url: String) -> String? {
        if !slug.isEmpty {
            return normalizeSlug(slug)
        }
        return Self.slug(from: url)
    }

    private static func slug(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString) else { return nil }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let last = path.split(separator: "/").last, !last.isEmpty else { return nil }
        return normalizeSlug(String(last))
    }

    private static func normalizeSlug(_ value: String) -> String {
        normalize(value)
            .replacingOccurrences(of: " ", with: "-")
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

extension UIBarButtonItem {
    static func appNavIcon(
        systemName: String,
        target: Any?,
        action: Selector,
        accessibilityLabel: String? = nil
    )
        -> UIBarButtonItem
    {
        let item = UIBarButtonItem(
            image: UIImage(systemName: systemName),
            style: .plain,
            target: target,
            action: action
        )
        item.tintColor = .label
        item.accessibilityLabel = accessibilityLabel
        return item
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Date {
    // example: // Change the component to your preference
    // let difference = Date().interval(ofComponent: .day, fromDate: yesterday) // returns 1
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        let currentCalendar = Calendar.current
        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
        return end - start
    }

    func toString(withFormat format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let myString = formatter.string(from: self)
        guard let yourDate = formatter.date(from: myString) else {
            return myString
        }
        formatter.dateFormat = format

        return formatter.string(from: yourDate)
    }
}

class ImageStore: NSObject {
    static let imageCache = NSCache<NSString, UIImage>()
}

extension UIImageView {
    func url(_ url: String?) {
        DispatchQueue.global().async { [weak self] in
            guard let stringURL = url, let url = URL(string: stringURL) else {
                return
            }
            func setImage(image: UIImage?) {
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
            let urlToString = url.absoluteString as NSString
            if let cachedImage = ImageStore.imageCache.object(forKey: urlToString) {
                setImage(image: cachedImage)
            } else if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    ImageStore.imageCache.setObject(image, forKey: urlToString)
                    setImage(image: image)
                }
            } else {
                setImage(image: nil)
            }
        }
    }
}

extension UIViewController {
    class func displaySpinner(onView: UIView, effect: UIBlurEffect) -> UIView {
        let blurEffectView = UIVisualEffectView(effect: effect)
        let loadingView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        let spinnerView = UIView(frame: onView.frame)
        spinnerView.backgroundColor = .clear
        let ai = UIActivityIndicatorView(style: .large)
        ai.startAnimating()
        ai.tintColor = .label
        ai.center = CGPoint(x: onView.bounds.width / 2, y: onView.bounds.height / 2)
        blurEffectView.frame = onView.bounds
        loadingView.center = CGPoint(x: onView.bounds.width / 2, y: onView.bounds.height / 2)
        loadingView.backgroundColor = .systemBackground
        DispatchQueue.main.async {
            spinnerView.addSubview(blurEffectView)
            spinnerView.addSubview(loadingView)
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }

        return spinnerView
    }

    class func removeSpinner(spinner: UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}

extension HTTPURLResponse {
    func isResponseOK() -> Bool {
        return (200 ... 299).contains(statusCode)
    }
}

extension Date {
    func localDate() -> Date {
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: self))
        return addingTimeInterval(timeZoneOffset)
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? startOfDay
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth) ?? self
    }

    func isMonday() -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday], from: self)
        return components.weekday == 2
    }
}

extension Array {
    func filterDuplicates(includeElement: (_ lhs: Element, _ rhs: Element) -> Bool) -> [Element] {
        var results = [Element]()

        forEach { element in
            let existingElements = results.filter {
                includeElement(element, $0)
            }
            if existingElements.isEmpty {
                results.append(element)
            }
        }

        return results
    }
}

extension UIImage {
    public class func gifImageWithName(_ name: String) -> UIImage? {
        guard
            let bundleURL = Bundle.main
                .url(forResource: name, withExtension: "gif")
        else {
            AppLogger.cache.error("SwiftGif missing image named \(name, privacy: .public)")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            AppLogger.cache.error("SwiftGif failed to load image data for \(name, privacy: .public)")
            return nil
        }

        return gifImageWithData(imageData)
    }

    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            AppLogger.cache.error("SwiftGif failed to create image source from data")
            return nil
        }

        return UIImage.animatedImageWithSource(source)
    }

    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1

        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(
                cfProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
            ),
            to: CFDictionary.self
        )

        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(
                gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()
            ),
            to: AnyObject.self
        )
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(
                gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()
            ), to: AnyObject.self)
        }

        delay = delayObject as? Double ?? 0.1

        if delay < 0.1 {
            delay = 0.1
        }

        return delay
    }

    class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        guard var a else {
            return b ?? 0
        }
        guard var b else {
            return a
        }

        if a < b {
            swap(&a, &b)
        }

        var rest: Int
        while true {
            rest = a % b

            if rest == 0 {
                return b
            } else {
                a = b
                b = rest
            }
        }
    }

    class func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }

        return gcd
    }

    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        for i in 0 ..< count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }

            let delaySeconds = UIImage.delayForImageAtIndex(
                Int(i),
                source: source
            )
            delays.append(Int(delaySeconds * 300)) // Seconds to ms
        }

        let duration: Int = {
            var sum = 0

            for val: Int in delays {
                sum += val
            }

            return sum
        }()

        let gcd = gcdForArray(delays)
        var frames = [UIImage]()

        var frame: UIImage
        var frameCount: Int
        for i in 0 ..< count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)

            for _ in 0 ..< frameCount {
                frames.append(frame)
            }
        }

        return UIImage.animatedImage(
            with: frames,
            duration: Double(duration) / 1000.0
        )
    }
}

public extension NSMutableAttributedString {
    class func setIconWithTitleString(isSuccess: Bool, isCaution: Bool, text: String) -> NSMutableAttributedString {
        let attrs = [
            NSAttributedString.Key.font:
                UIFont.systemFont(ofSize: 22.0, weight: .semibold),
            NSAttributedString.Key.strokeColor:
                UIColor.label
        ]
        let attr0 = [NSAttributedString.Key.font:
            UIFont.systemFont(ofSize: 25.0)]
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = isSuccess ?
            UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.systemGreen) : isCaution ?
            UIImage(systemName: "exclamationmark.circle.fill")?.withTintColor(.systemOrange) :
            UIImage(systemName: "exclamationmark.triangle.fill")?.withTintColor(.systemOrange)
        let image1String = NSAttributedString(attachment: image1Attachment)
        let fullString = NSMutableAttributedString(string: "", attributes: attr0)
        fullString.append(image1String)
        fullString.append(NSMutableAttributedString(string: " ", attributes: attr0))
        let content = NSMutableAttributedString(string: text, attributes: attrs)
        fullString.append(content)
        return fullString
    }

    class func setIconWithSmallLabelString(isSuccess: Bool, isCaution: Bool, text: String) -> NSMutableAttributedString {
        let attrs = [
            NSAttributedString.Key.font:
                UIFont.systemFont(ofSize: 12.0, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor.label
        ]
        let attr0 = [NSAttributedString.Key.font:
            UIFont.systemFont(ofSize: 12.0)]
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = isSuccess ?
            UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.systemGreen) : isCaution ?
            UIImage(systemName: "exclamationmark.circle.fill")?.withTintColor(.systemOrange) :
            UIImage(systemName: "exclamationmark.triangle.fill")?.withTintColor(.systemOrange)
        let image1String = NSAttributedString(attachment: image1Attachment)
        let fullString = NSMutableAttributedString(string: "", attributes: attr0)
        fullString.append(image1String)
        fullString.append(NSMutableAttributedString(string: " ", attributes: attr0))
        let content = NSMutableAttributedString(string: text, attributes: attrs)
        fullString.append(content)
        return fullString
    }

    class func setCustomIconWithTitleString(
        icon: NSMutableAttributedString,
        text: String
    )
        -> NSMutableAttributedString
    {
        let attrs = [
            NSAttributedString.Key.font:
                UIFont.systemFont(ofSize: 22.0, weight: .semibold),
            NSAttributedString.Key.strokeColor:
                UIColor.label
        ]
        let fullString = NSMutableAttributedString(string: " ", attributes: attrs)
        fullString.append(icon)
        let content = NSMutableAttributedString(string: text, attributes: attrs)
        fullString.append(content)
        return fullString
    }
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}
