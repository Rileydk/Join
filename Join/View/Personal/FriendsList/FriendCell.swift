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
        case projectGroupMemberSelection
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
        backgroundColor = .Gray6
        contentView.backgroundColor = .Gray6
        selectImageView.tintColor = .Blue1
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
        if let imageURL = friend.thumbnailURL {
            thumbnailImageView.loadImage(imageURL)
        } else {
            thumbnailImageView.image = UIImage(named: JImages.Icon_UserDefault.rawValue)
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
