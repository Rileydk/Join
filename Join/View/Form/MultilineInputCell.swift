//
//  MultilineInputCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class MultilineInputCell: TableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignalLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.addUnderline()
    }

    func layoutCell(info: ItemInfo) {
        titleLabel.text = info.name
        mustFillSignalLabel.isHidden = !info.must
        instructionLabel.text = info.instruction
    }
}
