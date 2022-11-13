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
    @IBOutlet weak var unreadMessagesAmountButton: UIButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userThumbnailImageView.image = nil
        nameLabel.text = ""
        latestMessageLabel.text = nil
        unreadMessagesAmountButton.isHidden = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        unreadMessagesAmountButton.isHidden = true
        contentView.backgroundColor = .Gray5
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        userThumbnailImageView.layer.cornerRadius = userThumbnailImageView.frame.size.width / 2
        unreadMessagesAmountButton.layer.cornerRadius = unreadMessagesAmountButton.frame.size.height / 2
        unreadMessagesAmountButton.isEnabled = false
    }

    func layoutCell(messageItem: MessageListItem) {
        firebaseManager.getUserInfo(id: messageItem.objectID) { [weak self] result in
            switch result {
            case .success(let user):
                self?.firebaseManager.downloadImage(urlString: user.thumbnailURL) { [weak self] result in
                    switch result {
                    case .success(let image):
                        self?.userThumbnailImageView.image = image
                        self?.nameLabel.text = user.name
                        if let latesMessage = messageItem.messages.first {
                            self?.latestMessageLabel.text = latesMessage.content
                        }

                        let amountOfUnreadMessages = messageItem.messages.filter {
                            $0.time > messageItem.lastTimeInChatroom
                        }.count
                        if amountOfUnreadMessages != 0 {
                            self?.unreadMessagesAmountButton.setTitle("\(amountOfUnreadMessages)", for: .normal)
                            self?.unreadMessagesAmountButton.isHidden = false
                        }
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
                self?.latestMessageLabel.text = groupMessageItem.messages.first?.content ?? ""

                let amountOfUnreadMessages = groupMessageItem.messages.filter {
                    $0.time > groupMessageItem.lastTimeInChatroom
                }.count
                if amountOfUnreadMessages != 0 {
                    self?.unreadMessagesAmountButton.setTitle("\(amountOfUnreadMessages)", for: .normal)
                    self?.unreadMessagesAmountButton.isHidden = false
                }
            case .failure(let err):
                print(err)
            }
        }
    }
}
