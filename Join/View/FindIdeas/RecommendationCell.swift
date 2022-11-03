//
//  AttentionCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/2.
//

import UIKit

class RecommendationCell: CollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    let firebaseManager = FirebaseManager.shared

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
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
