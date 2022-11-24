//
//  AttentionCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/2.
//

import UIKit

class RecommendedProjectCell: CollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: PaddingableLabel!

    let firebaseManager = FirebaseManager.shared

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.masksToBounds = false
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowColor = UIColor.Gray1?.cgColor

        contentView.layer.cornerRadius = 12

        titleLabel.backgroundColor = UIColor.gray.withAlphaComponent(0.4)
        titleLabel.layer.masksToBounds = true
        titleLabel.layer.cornerRadius = 4
        imageView.layer.cornerRadius = 12
    }

    func layoutCell(project: Project) {
        titleLabel.text = project.name
        if let imageURLString = project.imageURL {
            imageView.isHidden = false
            firebaseManager.downloadImage(urlString: imageURLString) { [weak self] result in
                switch result {
                case .success(let image):
                    self?.imageView.image = image
                case .failure(let error):
                    print(error)
                }
            }
        } else {
            imageView.isHidden = true
        }
    }
}
