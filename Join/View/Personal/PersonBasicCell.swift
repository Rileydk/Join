//
//  PersonBasicCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/4.
//

import UIKit

class PersonBasicCell: CollectionViewCell {
    let firebaseManager = FirebaseManager.shared
    var sendFriendRequestHandler: (() -> Void)?
    var acceptFriendRequestHandler: (() -> Void)?

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var relationshipButton: UIButton!
    @IBOutlet weak var sendMessageButton: UIButton!

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
    }

    private func layoutCell(image: UIImage, name: String) {
        nameLabel.text = name
        thumbnailImageView.image = image
    }

    func layoutCell(withSelf user: User, image: UIImage) {
        layoutCell(image: image, name: user.name)
        relationshipButton.isHidden = true
        sendMessageButton.isHidden = true
    }

    func layoutCell(withOther user: User, thumbnail: UIImage, relationship: Relationship) {
        layoutCell(image: thumbnail, name: user.name)
        if user.id == myAccount.id {
            relationshipButton.isHidden = true
            sendMessageButton.isHidden = true
        } else {
            relationshipButton.isHidden = false
            sendMessageButton.isHidden = false

            switch relationship {
            case .friend:
                self.relationshipButton.isEnabled = true
                self.relationshipButton.setTitle(Relationship.friend.title, for: .normal)
                self.tag = 0
            case .sentRequest:
                self.relationshipButton.isEnabled = false
                self.relationshipButton.setTitle(Relationship.sentRequest.title, for: .normal)
                self.relationshipButton.tag = 1
            case .receivedRequest:
                self.relationshipButton.isEnabled = true
                self.relationshipButton.setTitle(Relationship.receivedRequest.title, for: .normal)
                self.relationshipButton.tag = 2
            case .unknown:
                self.relationshipButton.isEnabled = true
                self.relationshipButton.setTitle(Relationship.unknown.title, for: .normal)
                self.relationshipButton.tag = 3
            }
        }
    }

    @IBAction func changeRelationship(_ sender: Any) {
        if let button = sender as? UIButton {
            let state = Relationship.allCases[button.tag]
            switch state {
            case .unknown:
                sendFriendRequestHandler?()
            case .receivedRequest:
                acceptFriendRequestHandler?()
            default: break
            }
        }
    }

    @IBAction func sendMessage(_ sender: UIButton) {
        
    }
}
