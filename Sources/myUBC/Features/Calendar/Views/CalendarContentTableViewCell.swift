//
//  CalendarContentTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2021-01-31.
//

import UIKit

class CalendarContentTableViewCell: UITableViewCell {
    static var nib: String {
        return "CalendarContentTableViewCell"
    }

    @IBOutlet var baseView: UIView!
    @IBOutlet var bar: UIView!
    @IBOutlet var eventDetail: UILabel!
    private let spinner = UIActivityIndicatorView(style: .medium)

    var campusEventDetail: CampusEventDetail?

    var isFirst = false
    var isLast = false

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupCorners() {
        /*
         layerMaxXMaxYCorner - bottom right corner
         layerMaxXMinYCorner - top right corner
         layerMinXMaxYCorner - bottom left corner
         layerMinXMinYCorner - top left corner
         */
        if isFirst, isLast {
            baseView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
        } else if isFirst {
            baseView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            baseView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else {
            baseView.layer.maskedCorners = []
        }
    }

    func setupUI() {
        baseView.clipsToBounds = true
        baseView.layer.masksToBounds = true
        baseView.layer.cornerRadius = 8

        if spinner.superview == nil {
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.hidesWhenStopped = true
            baseView.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: baseView.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: baseView.centerYAnchor)
            ])
        }
    }

    func setupModel(model: CampusEventDetail) {
        spinner.stopAnimating()
        bar.isHidden = false
        eventDetail.isHidden = false
        campusEventDetail = model
        bar.backgroundColor = (model.isImportant) ? #colorLiteral(red: 0.8510990296, green: 0.226861841, blue: 0.1955896148, alpha: 1) : #colorLiteral(red: 0, green: 0.6606139541, blue: 0.9780436158, alpha: 1)
        let str = model.eventDescription.replacingOccurrences(of: ". ", with: ".\n")
        eventDetail.text = str
    }

    func setNoEvent() {
        spinner.stopAnimating()
        bar.isHidden = false
        eventDetail.isHidden = false
        eventDetail.text = "No Event"
        bar.backgroundColor = .label
        bar.alpha = 0.8
    }

    func setLoading() {
        campusEventDetail = nil
        bar.isHidden = true
        eventDetail.isHidden = true
        spinner.startAnimating()
    }
}
