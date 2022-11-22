//
//  MultilineInputCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class MultilineInputCell: TableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var textView: PaddingableTextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func layoutCellForFindPartnerProjectDescription(title: String, value: String, shouldFill: Bool) {
        titleLabel.text = title
        mustFillSignLabel.isHidden = !shouldFill
        if value.isEmpty {
            textView.contentType = .placeholder
            textView.text = Constant.FindPartners.projectDescription
            textView.textColor = (UIColor.Gray3 ?? .lightGray).withAlphaComponent(0.7)
        } else {
            textView.contentType = .userInput
            textView.text = value
            textView.textColor = UIColor.Gray2
        }
    }

    func layoutCellForEditProfile(introduction: String) {
        titleLabel.text = "請填寫個人簡介"
        mustFillSignLabel.isHidden = true
        textView.text = introduction
    }
}
