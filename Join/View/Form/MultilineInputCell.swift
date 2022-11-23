//
//  MultilineInputCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class MultilineInputCell: TableViewCell {
    enum SourceType {
        case findPartnersDescription
        case findPartnersSkill
        case personalEditIntroduction
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var textView: PaddingableTextView!

    var sourceType: SourceType = .findPartnersDescription

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func layoutCellForFindPartner(title: String, value: String, shouldFill: Bool) {
        titleLabel.text = title
        mustFillSignLabel.isHidden = !shouldFill
        if value.isEmpty {
            textView.contentType = .placeholder
            if sourceType == .findPartnersDescription {
                textView.text = Constant.FindPartners.projectDescription
            }
            if sourceType == .findPartnersSkill {
                textView.text = Constant.FindPartners.recruitingSkillsPlaceholder
            }
            textView.textColor = (UIColor.Gray3 ?? .lightGray).withAlphaComponent(0.7)
        } else {
            textView.contentType = .userInput
            textView.text = value
            textView.textColor = UIColor.Gray2
        }
    }

    func layoutCellForEditProfile(introduction: String) {
        titleLabel.text = Constant.Edit.editIntroduction
        mustFillSignLabel.isHidden = true
        textView.text = introduction
    }
}
