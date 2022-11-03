//
//  IdeaCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/2.
//

import UIKit

class IdeaCell: CollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var deadlineLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    let firebaseManager = FirebaseManager.shared

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func layoutCell(project: Project) {
        titleLabel.text = project.name
        tagLabel.text = project.categories.first!
        deadlineLabel.text = project.deadline?.formatted
        locationLabel.text = project.location
        positionLabel.text = project.recruiting.first!.role
        numberLabel.text = "* \(project.recruiting.first!.number)"

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
