//
//  GroupMemberCircleBadgeCollectionReusableView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/27.
//

import UIKit

class BadgeSupplementaryView: UICollectionReusableView {
    static let identifier = String(describing: BadgeSupplementaryView.self)

    override init(frame: CGRect) {
        super.init(frame: frame)

    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func configure() {
        backgroundColor = .White?.withAlphaComponent(0.9)
        let closeIconImageView = UIImageView(image: UIImage(named: JImages.Icon_24px_Close.rawValue))
        addSubview(closeIconImageView)
        NSLayoutConstraint.activate([
            closeIconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            closeIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        closeIconImageView.isUserInteractionEnabled = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
    }
}
