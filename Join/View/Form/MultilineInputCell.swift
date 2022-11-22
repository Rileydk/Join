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
//        textView.backgroundColor = .Gray5
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
//        textView.addUnderline()
    }

    func layoutCellForFindPartner(title: String, shouldFill: Bool) {
        titleLabel.text = title
        mustFillSignLabel.isHidden = !shouldFill
        textView.text = Constant.FindPartners.projectDescription
//        textView.textColor = .Gray3
    }

    func layoutCellForEditProfile(introduction: String) {
        titleLabel.text = "請填寫個人簡介"
        mustFillSignLabel.isHidden = true
        textView.text = introduction
    }
}
