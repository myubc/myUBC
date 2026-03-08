//
//  HomeCollectionViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-19.
//

import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var baseView: UIView!
    @IBOutlet var shadowView: UIView!
    @IBOutlet var imageView: UIImageView!

    static var nibName: String {
        return "HomeCollectionViewCell"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    func setupViews() {
        layer.masksToBounds = false
        baseView.layer.cornerRadius = 8
        baseView.layer.masksToBounds = true
        shadowView.layer.masksToBounds = false
        shadowView.layer.cornerRadius = 8
        shadowView.layer.shadowColor = UIColor.darkGray.cgColor
        shadowView.layer.shadowRadius = 8
        shadowView.layer.shadowOpacity = 0.3
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    func setupContent(title: String, subtitle: String, img: String) {
        self.title.text = title
        self.subtitle.text = subtitle
        imageView.image = UIImage(named: img)
    }
}
