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
    @IBOutlet weak var savingButton: UIButton!
    @IBOutlet weak var applicantsAmountLabelButton: UIButton!

    let firebaseManager = FirebaseManager.shared

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applicantsAmountLabelButton.isEnabled = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applicantsAmountLabelButton.layer.cornerRadius = applicantsAmountLabelButton.frame.size.height / 2
    }

    func layoutCell(project: Project) {
        titleLabel.text = project.name
        tagLabel.text = project.categories.first!
        deadlineLabel.text = project.deadline?.formatted
        locationLabel.text = project.location
        positionLabel.text = project.recruiting.first!.role
        numberLabel.text = "* \(project.recruiting.first!.number)"
        applicantsAmountLabelButton.isHidden = true

        if let imageURLString = project.imageURL {
            imageView.isHidden = false
            imageView.loadImage(imageURLString)
        } else {
            imageView.isHidden = true
        }
    }

    func layoutCellWithApplicants(project: Project) {
        layoutCell(project: project)
        savingButton.isHidden = true
        if !project.applicants.isEmpty {
            applicantsAmountLabelButton.isHidden = false
            applicantsAmountLabelButton.setTitle("應徵數: \(project.applicants.count)", for: .normal)
        }
    }
}
