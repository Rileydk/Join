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

    func layoutCell(image: UIImage?, message: String) {
        if let image = image {
            thumbnailImageView.image = image
        } else {
            print("image is nil")
        }
        messageTextView.text = message
    }

    @objc func thumbnailGetTapped() {
        tapHandler?()
    }
}
