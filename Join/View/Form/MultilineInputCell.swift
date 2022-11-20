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
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.addUnderline()
    }

    func layoutCellForFindPartner(title: String, shouldFill: Bool, instruction: String) {
        titleLabel.text = title
        mustFillSignLabel.isHidden = !shouldFill
        instructionLabel.text = instruction
    }

    func layoutCellForEditProfile(introduction: String) {
        titleLabel.text = "請填寫個人簡介"
        mustFillSignLabel.isHidden = true
        instructionLabel.isHidden = true
        textView.text = introduction
    }
}
