//
//  RelationshipButtonsCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import UIKit

class RelationshipButtonsCell: CollectionViewCell {
    @IBOutlet weak var relationshipButton: UIButton!
    @IBOutlet weak var sendMessageButton: UIButton!

    var sendFriendRequestHandler: (() -> Void)?
    var acceptFriendRequestHandler: (() -> Void)?
    var goChatroomHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        relationshipButton.layer.cornerRadius = 8
        relationshipButton.backgroundColor = .Blue3
        sendMessageButton.layer.cornerRadius = 8
        sendMessageButton.layer.borderWidth = 0.5
        sendMessageButton.setTitleColor(.Gray3, for: .normal)
        sendMessageButton.layer.borderColor = (UIColor.Gray4 ?? .lightGray).cgColor
        sendMessageButton.backgroundColor = .White
    }

    func layoutCell(with relationship: Relationship?) {
        guard let relationship = relationship else { return }

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
        default:
            break
        }
    }

    @IBAction func changeRelationship(_ sender: UIButton) {
        let button = sender as UIButton
        let state = Relationship.allCases[button.tag]
        switch state {
        case .unknown:
            sendFriendRequestHandler?()
        case .receivedRequest:
            acceptFriendRequestHandler?()
        default: break
        }
    }

    @IBAction func sendMessage(_ sender: UIButton) {
        goChatroomHandler?()
    }
}
