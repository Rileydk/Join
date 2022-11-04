//
//  PersonBasicCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/4.
//

import UIKit

class PersonBasicCell: CollectionViewCell {
    let firebaseManager = FirebaseManager.shared

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

    private func layoutCell(imageURLString: URLString, name: String) {
        firebaseManager.downloadImage(urlString: imageURLString) { [weak self] result in
            switch result {
            case .success(let image):
                self?.thumbnailImageView.image = image
            case .failure(let error):
                print(error)
            }
        }
        nameLabel.text = name
    }

    func layoutCell(withSelf user: User) {
        layoutCell(imageURLString: user.thumbnailURL, name: user.name)
        relationshipButton.isHidden = true
        sendMessageButton.isHidden = true
    }

    func layoutCell(withOther user: User) {
        layoutCell(imageURLString: user.thumbnailURL, name: user.name)
        relationshipButton.isHidden = false
        sendMessageButton.isHidden = false
    }

    @IBAction func changeRelationship(_ sender: Any) {
    }
    @IBAction func sendMessage(_ sender: UIButton) {
    }
}
