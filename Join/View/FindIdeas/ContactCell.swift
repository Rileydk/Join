//
//  ProjectContactCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/4.
//

import UIKit

class ContactCell: TableViewCell {
    let firebaseManager = FirebaseManager.shared

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameButton: UIButton!

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

    func layoutCell(user: User) {
        firebaseManager.downloadImage(urlString: user.thumbnailURL) { [weak self] result in
            switch result {
            case .success(let image):
                self?.thumbnailImageView.image = image
            case .failure(let error):
                print(error)
            }
        }
        nameButton.setTitle(user.name, for: .normal)
    }

    @IBAction func goProfilePage(_ sender: UIButton) {
        tapHandler?()
    }

    @IBAction func sendMessage(_ sender: UIButton) {
        messageHandler?()
    }
}
