//
//  PersonalMainThumbnailCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class PersonalMainThumbnailCell: TableViewCell {
    let firebaseManager = FirebaseManager.shared

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
    }

    func layoutCell(user: JUser) {
        firebaseManager.downloadImage(urlString: user.thumbnailURL) { [weak self] result in
            switch result {
            case .success(let image):
                self?.thumbnailImageView.image = image
            case .failure(let error):
                print(error)
            }
        }
        nameLabel.text = user.name
    }
}
