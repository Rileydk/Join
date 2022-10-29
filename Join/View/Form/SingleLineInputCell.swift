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

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutViews()
    }

    func layoutViews() {
        textField.borderStyle = .none
        textField.addUnderline()
    }
}
