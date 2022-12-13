//
//  MessageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit

class MessageCell: TableViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var timeLabel: UILabel!

    let firebaseManager = FirebaseManager.shared
    var tapHandler: (() -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
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

        thumbnailImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(thumbnailGetTapped))
        thumbnailImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
    }

    func layoutCell(imageURL: URLString?, message: Message) {
        if let imageURL = imageURL {
            thumbnailImageView.loadImage(imageURL)
        } else {
            thumbnailImageView.image = UIImage(named: JImages.Icon_UserDefault.rawValue)
        }
        messageTextView.text = message.content
        timeLabel.text = message.time.formattedTime
    }

    @objc func thumbnailGetTapped() {
        tapHandler?()
    }
}
