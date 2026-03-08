//
//  TitleSupplementaryView.swift
//  myUBC
//
//  Created by myUBC on 2022-09-07.
//

import UIKit

class TitleSupplementaryView: UICollectionReusableView {
    let label = UILabel()
    let link = UIButton()
    static let reuseIdentifier = "title-supplementary-reuse-identifier"

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension TitleSupplementaryView {
    func configure() {
        addSubview(label)
        addSubview(link)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        link.translatesAutoresizingMaskIntoConstraints = false
        let inset = CGFloat(10)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset + 5),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset * 4),
            label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset / 5),

            link.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 0),
            link.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            link.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            link.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset / 5)

        ])
        label.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
        link.setTitle("More", for: .normal)
        link.tintColor = UIColor.link
    }
}
