//
//  FriendCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/7.
//

import UIKit

class FriendCell: TableViewCell {
    enum Source {
        case friendList
        case friendSelection
    }

    let firebaseManager = FirebaseManager.shared

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectImageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .Gray5
        contentView.backgroundColor = .Gray5
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func layoutCell(friend: JUser, source: Source) {
        nameLabel.text = friend.name
        firebaseManager.downloadImage(urlString: friend.thumbnailURL) { [weak self] result in
            switch result {
            case .success(let image):
                self?.thumbnailImageView.image = image
            case .failure(let error):
                print(error)
            }
        }
        if source == .friendSelection {
            selectImageView.isHidden = false
        } else {
            selectImageView.isHidden = true
        }
    }

    func layoutCell(friend: JUser, source: Source, isMember: Bool, isSelectedNow: Bool) {
        layoutCell(friend: friend, source: source)

        if isMember {
            print("isMember")
            selectImageView.isHidden = true
            thumbnailImageView.alpha = 0.5
            nameLabel.textColor = .lightGray
            selectionStyle = .none
        } else {
            selectImageView.isHidden = false
        }

        if isSelectedNow {
            selectImageView.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            selectImageView.image = UIImage(systemName: "checkmark.circle")
        }
    }
}
