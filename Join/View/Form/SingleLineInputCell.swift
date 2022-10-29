//
//  FindPartners.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class SingleLineInputCell: TableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignalLabel: UILabel!
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
        mustFillSignalLabel.isHidden = !info.must
        instructionLabel.text = info.instruction
    }
}
