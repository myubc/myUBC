//
//  CalendarCollectionViewCell.swift
//  myUBC
//
//  Created by myUBC on 2022-09-03.
//

import UIKit

class CalendarCollectionViewCell: UICollectionViewCell {
    static var nib: String {
        return "CalendarCollectionViewCell"
    }

    @IBOutlet var DayString: UILabel!
    @IBOutlet var numberString: UILabel!
    @IBOutlet var monthString: UILabel!

    @IBOutlet var event1: UIView!
    @IBOutlet var event1Ribbon: UIView!
    @IBOutlet var event1Content: UILabel!

    @IBOutlet var event2: UIView!
    @IBOutlet var event2Content: UILabel!
    @IBOutlet var event2Ribbon: UIView!

    @IBOutlet var extraLabel: UILabel!

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

    func setup(for today: [CampusEventDetail]) {
        let date = Date()
        numberString.text = String(date.get(.day))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        monthString.text = dateFormatter.string(from: date)
        let dateFormatterWeek = DateFormatter()
        dateFormatterWeek.dateFormat = "EEE"
        DayString.text = dateFormatterWeek.string(from: date)

        setupLabel1(today: today)
        setupLabel2(today: today)
        LandingCardShadowStyler.refreshShadowColor(from: baseView, to: shadowView)
    }

    func setupLabel1(today: [CampusEventDetail]) {
        if
            let isImporant = today.first?.isImportant,
            let str = today.first?.eventDescription
        {
            if isImporant {
                setLabel1Imporant(str: str)
            } else {
                setLabel1Regular(str: str)
            }
        } else {
            event1.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            event1Ribbon.backgroundColor = UIColor.black.withAlphaComponent(0.9)
            event1Content.text = "No events today"
            event1Content.textColor = UIColor.label
        }
    }

    func setupLabel2(today: [CampusEventDetail]) {
        var temp = today
        if !temp.isEmpty { temp.removeFirst() }
        if
            let isImporant = temp.first?.isImportant,
            let str = temp.first?.eventDescription
        {
            if isImporant {
                setLabel2Imporant(str: str)
            } else {
                setLabel2Regular(str: str)
            }
            event2.isHidden = false
            extraLabel.isHidden = (today.count > 2) ? false : true
            extraLabel.text = "+ \(today.count - 2) others"
        } else {
            event2.isHidden = true
            extraLabel.isHidden = true
        }
    }

    func setLabel1Imporant(str: String) {
        event1.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        event1Ribbon.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
        event1Content.text = str
        event1Content.textColor = UIColor.systemRed
    }

    func setLabel2Imporant(str: String) {
        event2.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        event2Ribbon.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
        event2Content.text = str
        event2Content.textColor = UIColor.systemRed
    }

    func setLabel1Regular(str: String) {
        if #available(iOS 15.0, *) {
            event1.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.3)
            event1Ribbon.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.9)
            event1Content.textColor = UIColor.systemCyan
        } else {
            let colour = UIColor(red: 61, green: 173, blue: 224, alpha: 1)
            event1.backgroundColor = colour.withAlphaComponent(0.3)
            event1Ribbon.backgroundColor = colour.withAlphaComponent(0.9)
            event1Content.textColor = colour
        }
        event1Content.text = str
    }

    func setLabel2Regular(str: String) {
        if #available(iOS 15.0, *) {
            event2.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.3)
            event2Ribbon.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.9)
            event2Content.textColor = UIColor.systemCyan
        } else {
            let colour = UIColor(red: 61, green: 173, blue: 224, alpha: 0)
            event2.backgroundColor = colour.withAlphaComponent(0.3)
            event2Ribbon.backgroundColor = colour.withAlphaComponent(0.9)
            event2Content.textColor = colour
        }
        event2Content.text = str
    }
}
