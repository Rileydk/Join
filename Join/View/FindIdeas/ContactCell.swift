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

    let firebaseManager = FirebaseManager.shared
    var tapHandler: (() -> Void)?
    var messageHandler: (() -> Void)?

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
    }

    func layoutCell(user: JUser, from source: Source) {
        thumbnailImageView.loadImage(user.thumbnailURL ?? FindPartnersFormSections.placeholderImageURL)
//        firebaseManager.downloadImage(urlString: user.thumbnailURL ?? FindPartnersFormSections.placeholderImageURL) { [weak self] result in
//            switch result {
//            case .success(let image):
//                self?.thumbnailImageView.image = image
//            case .failure(let error):
//                print(error)
//            }
//        }
        nameButton.setTitle(user.name, for: .normal)
        let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? ""
        if source == .myPostContact || (source == .projectDetails && user.id == myID) {
            messageButton.isHidden = true
        } else {
            messageButton.isHidden = false
        }
    }

    @IBAction func goProfilePage(_ sender: UIButton) {
        tapHandler?()
    }

    @IBAction func sendMessage(_ sender: UIButton) {
        messageHandler?()
    }
}
