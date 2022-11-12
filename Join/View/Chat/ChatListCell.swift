//
//  ChatListCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/6.
//

import UIKit

class ChatListCell: TableViewCell {
    let firebaseManager = FirebaseManager.shared

    @IBOutlet weak var userThumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var latestMessageLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        userThumbnailImageView.image = nil
        nameLabel.text = ""
        latestMessageLabel.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        userThumbnailImageView.layer.cornerRadius = userThumbnailImageView.frame.size.width / 2
    }

    func layoutCell(messageItem: MessageListItem) {
        firebaseManager.getUserInfo(id: messageItem.userID) { [weak self] result in
            switch result {
            case .success(let user):
                self?.firebaseManager.downloadImage(urlString: user.thumbnailURL) { [weak self] result in
                    switch result {
                    case .success(let image):
                        self?.userThumbnailImageView.image = image
                        self?.nameLabel.text = user.name
                        self?.latestMessageLabel.text = messageItem.latestMessage.content
                    case .failure(let error):
                        print(error)
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    func layoutCell(groupMessageItem: GroupMessageListItem) {
        firebaseManager.downloadImage(urlString: groupMessageItem.chatroom.imageURL) { [weak self] result in
            switch result {
            case .success(let image):
                self?.userThumbnailImageView.image = image
                self?.nameLabel.text = groupMessageItem.chatroom.name
                self?.latestMessageLabel.text = groupMessageItem.messages.last?.content ?? ""
            case .failure(let err):
                print(err)
            }
        }
    }
}
