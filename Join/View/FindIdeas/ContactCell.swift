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
        case myPosts
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
        thumbnailImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goProfilePage))
        thumbnailImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
    }

    func layoutCell(user: JUser, from source: Source) {
        firebaseManager.downloadImage(urlString: user.thumbnailURL) { [weak self] result in
            switch result {
            case .success(let image):
                self?.thumbnailImageView.image = image
            case .failure(let error):
                print(error)
            }
        }
        nameButton.setTitle(user.name, for: .normal)
        if source == .myPosts || user.id == myAccount.id {
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
