//
//  LandingFooter.swift
//  myUBC
//
//  Created by myUBC on 2022-09-08.
//

import UIKit

class LandingFooter: UICollectionReusableView {
    static var nib: String {
        return "LandingFooter"
    }

    @IBOutlet var copyright: UILabel!
    var action: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        copyright.text = "© \(Date().get(.year)) myUBC. All Rights Reserved"
    }

    @IBAction func didTapReview(_ sender: Any) {
        if let action = action {
            action()
        }
    }
}
