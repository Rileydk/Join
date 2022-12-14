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
    @IBOutlet weak var moreActionButton: UIButton!

    var sendFriendRequestHandler: (() -> Void)?
    var acceptFriendRequestHandler: (() -> Void)?
    var goChatroomHandler: (() -> Void)?
    var blockUserHandler: (() -> Void)?
    var reportUserHandler: (() -> Void)?

    let firebaseManager = FirebaseManager.shared

    override func awakeFromNib() {
        super.awakeFromNib()
        relationshipButton.layer.cornerRadius = 8
        relationshipButton.backgroundColor = .Blue3
        sendMessageButton.layer.cornerRadius = 8
        sendMessageButton.layer.borderWidth = 0.5
        sendMessageButton.setTitleColor(.Gray3, for: .normal)
        sendMessageButton.layer.borderColor = (UIColor.Gray4 ?? .lightGray).cgColor
        sendMessageButton.backgroundColor = .White

        moreActionButton.showsMenuAsPrimaryAction = true
        let reportAction = UIAction(
            title: Constant.Personal.report,
            attributes: [], state: .off) { [weak self] _ in
            self?.reportUserHandler?()
        }
        let blockAction = UIAction(
            title: Constant.Personal.block,
            attributes: [], state: .off) { [weak self] _ in
            self?.blockUser()
        }
        let elements: [UIAction] = [reportAction, blockAction]
        let menu = UIMenu(children: elements)
        moreActionButton.menu = menu
    }

    func layoutCell(with relationship: Relationship?, isBlocked: Bool) {
        guard let relationship = relationship else { return }

        switch relationship {
        case .friend:
            self.relationshipButton.setTitle(Relationship.friend.title, for: .normal)
            self.tag = 0
        case .sentRequest:
            self.relationshipButton.setTitle(Relationship.sentRequest.title, for: .normal)
            self.relationshipButton.tag = 1
        case .receivedRequest:
            self.relationshipButton.setTitle(Relationship.receivedRequest.title, for: .normal)
            self.relationshipButton.tag = 2
        case .unknown:
            self.relationshipButton.setTitle(Relationship.unknown.title, for: .normal)
            self.relationshipButton.tag = 3
        default:
            break
        }

        moreActionButton.showsMenuAsPrimaryAction = true
        let reportAction = UIAction(
            title: Constant.Personal.report,
            attributes: [], state: .off) { [weak self] _ in
            self?.reportUserHandler?()
        }
        var elements: [UIAction] = [reportAction]
        if !isBlocked {
            let blockAction = UIAction(
                title: Constant.Personal.block,
                attributes: [], state: .off) { [weak self] _ in
                self?.blockUser()
            }
            elements += [blockAction]
        }
        let menu = UIMenu(children: elements)
        moreActionButton.menu = menu

    }

    @IBAction func changeRelationship(_ sender: UIButton) {
        let button = sender as UIButton
        let state = Relationship.allCases[button.tag]
        switch state {
        case .unknown:
            sendFriendRequestHandler?()
        case .receivedRequest:
            acceptFriendRequestHandler?()
        case .sentRequest:
            print("sent request")
        case .friend:
            print("friend")
        default:
            break
        }
    }

    @IBAction func sendMessage(_ sender: UIButton) {
        goChatroomHandler?()
    }

    func blockUser() {
        blockUserHandler?()
    }
}
