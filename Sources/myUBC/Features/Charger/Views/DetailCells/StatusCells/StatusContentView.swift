//
//  StatusContentView.swift
//  myUBC
//
//  Created by myUBC on 2020-02-08.
//

import UIKit

class StatusContentView: UIView {
    @IBOutlet var refLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var separator: UIView!
    @IBOutlet var nextArrow: UIImageView!
    @IBOutlet var pushBtn: UIButton!

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
         // Drawing code
     }
     */

    class func instanceFromNib() -> UIView {
        return UINib(nibName: "StatusContentView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)
            .first as? UIView ?? UIView()
    }
}
