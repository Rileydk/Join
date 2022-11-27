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

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.width / 2
    }

    func layoutCell(user: JUser) {
        if  let imageURL = user.thumbnailURL,
            let url = URL(string: imageURL) {
            thumbnailImageView.kf.setImage(with: url)
        }
        nameLabel.text = user.name
    }
}
