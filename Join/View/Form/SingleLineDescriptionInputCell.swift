//
//  FindPartners.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class SingleLineDescriptionInputCell: TableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var textField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        textField.borderStyle = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // FIXME: - 長度錯誤
        textField.addUnderline()
    }

    func layoutCell(info: ItemInfo) {
        titleLabel.text = info.name
        mustFillSignLabel.isHidden = !info.must
        instructionLabel.text = info.instruction
    }
}
