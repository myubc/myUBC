//
//  DeviceTitleView.swift
//  myUBC
//
//  Created by myUBC on 2020-02-08.
//

import UIKit

class DeviceTitleView: UIView {
    @IBOutlet var title: UILabel!
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
         // Drawing code
     }
     */

    class func instanceFromNib() -> UIView {
        return UINib(nibName: "DeviceTitleView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)
            .first as? UIView ?? UIView()
    }
}
