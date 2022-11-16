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
        messageTextView.layer.borderWidth = 0.5
        messageTextView.layer.borderColor = UIColor.Gray3?.cgColor
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
        firebaseManager.downloadImage(urlString: message.sender.thumbnailURL ?? FindPartnersFormSections.placeholderImageURL) { [unowned self] result in
            switch result {
            case .success(let image):
                self.senderThumbnailImageView.image = image
            case .failure(let err):
                print(err)
            }
        }

        senderNameLabel.text = message.sender.name
        messageTextView.text = message.message.content
    }

    @objc func thumbnailGetTapped() {
        tapHandler?()
    }
}
