//
//  GroupMessageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/11.
//

import UIKit

class GroupMessageCell: TableViewCell {
    @IBOutlet weak var senderThumbnailImageView: UIImageView!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var timeLabel: UILabel!

    let firebaseManager = FirebaseManager.shared
    var tapHandler: (() -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        senderThumbnailImageView.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        let inset: CGFloat = 8
        messageTextView.textContainerInset = UIEdgeInsets(
            top: inset, left: inset,
            bottom: inset, right: inset
        )
        messageTextView.layer.cornerRadius = 12
        messageTextView.backgroundColor = .White
        messageTextView.isUserInteractionEnabled = false
        messageTextView.isScrollEnabled = false

        senderThumbnailImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(thumbnailGetTapped))
        senderThumbnailImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        senderThumbnailImageView.layer.cornerRadius = senderThumbnailImageView.frame.size.width / 2
    }

    func layoutCell(message: WholeInfoMessage) {
        if let imageURL = message.sender.thumbnailURL {
            senderThumbnailImageView.loadImage(imageURL)
        } else {
            senderThumbnailImageView.image = UIImage(named: JImages.Icon_UserDefault.rawValue)
        }
        senderNameLabel.text = message.sender.name
        messageTextView.text = message.message.content
        timeLabel.text = message.message.time.formattedTime
    }

    @objc func thumbnailGetTapped() {
        tapHandler?()
    }
}
