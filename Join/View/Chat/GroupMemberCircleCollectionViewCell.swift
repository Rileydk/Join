//
//  GroupMemberCircleCollectionViewCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/27.
//

import UIKit

class GroupMemberCircleCollectionViewCell: CollectionViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var deleteBadgeButton: UIButton!

    var deleteHandler: ((UIButton, UIEvent) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        if !deleteBadgeButton.isHidden {
            deleteBadgeButton.backgroundColor = .White?.withAlphaComponent(0.9)
            deleteBadgeButton.setImage(UIImage(named: JImages.Icon_24px_Close.rawValue), for: .normal)
            deleteBadgeButton.contentEdgeInsets = .init(top: 2, left: 2, bottom: 2, right: 2)
            deleteBadgeButton.layer.shadowOpacity = 0.2
            deleteBadgeButton.layer.shadowRadius = 2
            deleteBadgeButton.layer.shadowOffset = CGSize(width: 2, height: 2)
            deleteBadgeButton.layer.shadowColor = UIColor.black.cgColor
            deleteBadgeButton.addTarget(self, action: #selector(deleteSelectedMember), for: .touchUpInside)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.width / 2
        deleteBadgeButton.layer.cornerRadius = deleteBadgeButton.frame.width / 2
        NSLayoutConstraint.activate([
            deleteBadgeButton.topAnchor.constraint(
                equalTo: thumbnailImageView.topAnchor, constant: 5),
            deleteBadgeButton.leftAnchor.constraint(
                equalTo: thumbnailImageView.rightAnchor, constant: -15)
        ])
    }

    func layoutCell(user: JUser) {
        if  let imageURL = user.thumbnailURL,
            let url = URL(string: imageURL) {
            thumbnailImageView.kf.setImage(with: url)
        } else {
            thumbnailImageView.image = UIImage(named: JImages.Icon_UserDefault.rawValue)
        }
        nameLabel.text = user.name
    }

    @objc func deleteSelectedMember(sender: UIButton, event: UIEvent) {
        deleteHandler?(sender, event)
    }
}
