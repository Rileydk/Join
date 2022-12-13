//
//  ProjectContactCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/4.
//

import UIKit

class ContactCell: TableViewCell {
    enum Source {
        case projectDetails
        case myPostContact
        case myPostApplicant
    }

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var acceptJoinButton: UIButton!
    
    let firebaseManager = FirebaseManager.shared
    var tapHandler: (() -> Void)?
    var messageHandler: (() -> Void)?
    var acceptHandler: ((JUser) -> Void)?
    var user: JUser?
    var isMember: Bool?

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
        thumbnailImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goProfilePage))
        thumbnailImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
        acceptJoinButton.layer.cornerRadius = 8
    }

    func layoutCell(user: JUser, from source: Source, isMember: Bool? = nil) {
        if let imageURL = user.thumbnailURL {
            thumbnailImageView.loadImage(imageURL)
        } else {
            thumbnailImageView.image = UIImage(named: JImages.Icon_UserDefault.rawValue)
        }
        nameButton.setTitle(user.name, for: .normal)
        let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? ""
        if source == .myPostContact || source == .myPostApplicant ||
            (source == .projectDetails && user.id == myID) {
            messageButton.isHidden = true
        } else {
            messageButton.isHidden = false
        }

        if source == .myPostApplicant {
            acceptJoinButton.isHidden = false
            guard let isMember = isMember else { return }
            self.isMember = isMember
            if isMember {
                acceptJoinButton.setTitle("已是團隊成員", for: .normal)
                acceptJoinButton.setTitleColor(.Blue1, for: .normal)
                acceptJoinButton.backgroundColor = .clear
                acceptJoinButton.contentEdgeInsets = .init(top: 6, left: 12, bottom: 6, right: 0)
            } else {
                acceptJoinButton.setTitle("Join", for: .normal)
                acceptJoinButton.setTitleColor(.Blue1?.withAlphaComponent(0.7), for: .normal)
                acceptJoinButton.backgroundColor = .Blue1?.withAlphaComponent(0.2)
                acceptJoinButton.contentEdgeInsets = .init(top: 6, left: 12, bottom: 6, right: 12)
            }
        } else {
            acceptJoinButton.isHidden = true
        }
        self.user = user
    }

    @IBAction func goProfilePage(_ sender: UIButton) {
        tapHandler?()
    }

    @IBAction func sendMessage(_ sender: UIButton) {
        messageHandler?()
    }
    @IBAction func acceptJoin(_ sender: Any) {
        guard let user = user, let isMember = isMember else { return }
        if !isMember {
            acceptHandler?(user)
        }
    }
}
