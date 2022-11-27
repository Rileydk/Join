//
//  IdeaCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/2.
//

import UIKit

class IdeaCell: CollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deadlineLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var savingButton: UIButton!
    @IBOutlet weak var applicantsAmountLabel: PaddingableLabel!
    @IBOutlet weak var tagLabel: PaddingableLabel!
    @IBOutlet weak var moreImageView: UIImageView!

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
        if titleLabel.numberOfLines == 1 {
            layer.shadowRadius = 14
        } else {
            layer.shadowRadius = 30
        }
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowColor = UIColor.Gray1?.cgColor

        contentView.backgroundColor = .White
        contentView.layer.cornerRadius = 8

        tagLabel.backgroundColor = .Blue1?.withAlphaComponent(0.2)
        tagLabel.textColor = .Blue1?.withAlphaComponent(0.7)
        tagLabel.layer.borderWidth = 0.5
        tagLabel.layer.borderColor = UIColor.Blue1?.withAlphaComponent(0.7).cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applicantsAmountLabel.layer.cornerRadius = applicantsAmountLabel.frame.height / 2
        applicantsAmountLabel.layer.masksToBounds = true
        tagLabel.layer.cornerRadius = tagLabel.frame.height / 2
        tagLabel.clipsToBounds = true
    }

    func layoutCell(project: Project) {
        titleLabel.text = project.name
        if let firstTag = project.categories.first {
            tagLabel.text = firstTag
            if project.categories.count > 1 {
                moreImageView.isHidden = false
            } else {
                moreImageView.isHidden = true
            }
        }
        deadlineLabel.text = project.deadline?.formatted
        locationLabel.text = project.location
        positionLabel.text = project.recruiting.first!.role
        numberLabel.text = "* \(project.recruiting.first!.number)"
        applicantsAmountLabel.isHidden = true

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
            applicantsAmountLabel.isHidden = false
            applicantsAmountLabel.text = "應徵數: \(project.applicants.count)"
        }
    }
}
