//
//  NotificationTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-12.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var content: UILabel!
    @IBOutlet var moreBtn: UIButton!
    @IBOutlet var baseView: UIView!

    static var nibName: String {
        return Constants.notificationTableIdentifier
    }

    weak var notificationProtocol: NotificationProtocol?

    var model: CampusNotification? {
        didSet { setup() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        baseView.layer.cornerRadius = 8
    }

    @IBAction func didMoreBtn(_ sender: Any) {
        notificationProtocol?.showMore(id: model?.notificationID ?? "")
    }

    func setup() {
        moreBtn.layer.cornerRadius = 8
        title.text = model?.title
        subtitle.text = model?.time
        if let text = model?.content.components(separatedBy: " ") {
            var string = ""

            if text.count > 100 {
                string = text[0 ... 80].joined(separator: " ")
            } else {
                string = text.joined(separator: " ")
            }

            string = string.replacingOccurrences(of: "Dr.", with: "Dr,")
            string = string.replacingOccurrences(of: "Prof.", with: "Prof,")
            string = string.replacingOccurrences(of: "Mr.", with: "mr,")
            string = string.replacingOccurrences(of: "Mrs.", with: "Mrs,")
            string = string.replacingOccurrences(of: "Ms.", with: "Ms,")
            string = string.replacingOccurrences(of: "p.m.", with: "p,m,")
            string = string.replacingOccurrences(of: "a.m.", with: "a,m,")
            // string = string.replacingOccurrences(of: ". ", with: ".\n\n")
            string = string.replacingOccurrences(of: "Dr,", with: "Dr.")
            string = string.replacingOccurrences(of: "Prof,", with: "Prof.")
            string = string.replacingOccurrences(of: "Mr,", with: "mr.")
            string = string.replacingOccurrences(of: "Mrs,", with: "Mrs.")
            string = string.replacingOccurrences(of: "Ms,", with: "Ms.")
            string = string.replacingOccurrences(of: "p,m,", with: "p.m.")
            string = string.replacingOccurrences(of: "a,m,", with: "a.m.")

            content.text = string + " ..."
        }
    }
}
