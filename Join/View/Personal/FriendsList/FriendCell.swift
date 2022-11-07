//
//  FriendCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/7.
//

import UIKit

class FriendCell: TableViewCell {
    let firebaseManager = FirebaseManager.shared

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
    }

    func layoutCell(friend: User) {
        nameLabel.text = friend.name
        firebaseManager.downloadImage(urlString: friend.thumbnailURL) { [weak self] result in
            switch result {
            case .success(let image):
                self?.thumbnailImageView.image = image
            case .failure(let error):
                print(error)
            }
        }
    }
}
