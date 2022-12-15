//
//  PersonalMainThumbnailCollectionCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/19.
//

import UIKit

class PersonalMainThumbnailCollectionCell: CollectionViewCell {
    let firebaseManager = FirebaseManager.shared

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    var updateImage: ((UIImage) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.textColor = .Blue1
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
    }

    func layoutCell(user: JUser, backgroundColor: UIColor) {
        nameLabel.text = user.name
        if let imageURL = user.thumbnailURL {
            thumbnailImageView.loadImage(imageURL)
        } else {
            thumbnailImageView.image = UIImage(named: JImages.Icon_UserDefault.rawValue)
        }
        contentView.backgroundColor = backgroundColor
    }

}
