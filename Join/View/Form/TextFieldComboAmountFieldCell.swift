//
//  TextFieldComboAmountPickerCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/22.
//

import UIKit

class TextFieldComboAmountFieldCell: TableViewCell {
    @IBOutlet weak var longTextFieldTitleLabel: UILabel!
    @IBOutlet weak var longTextField: PaddingableTextField!
    @IBOutlet weak var shortTextFieldTitleLabel: UILabel!
    @IBOutlet weak var shortTextField: PaddingableTextField!

    var updateRecruitingRole: ((String) -> Void)?
    var updateRecruitingNumber: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func layoutCell(longFieldTitle: String, longFieldValue: String, longFieldPlaceholder: String, shortFieldTitle: String, shortFieldValue: String, shortFieldPlaceholder: String) {
        longTextFieldTitleLabel.text = longFieldTitle
        if longFieldValue.isEmpty {
            longTextField.attributedPlaceholder = NSAttributedString(
                string: longFieldPlaceholder, attributes: [
                    NSAttributedString.Key.foregroundColor: (UIColor.Gray3?.withAlphaComponent(0.7) ?? .lightGray).cgColor
                ])
        } else {
            longTextField.text = longFieldValue
        }

        shortTextFieldTitleLabel.text = shortFieldTitle
        if shortFieldValue.isEmpty {
            shortTextField.attributedPlaceholder = NSAttributedString(
                string: shortFieldPlaceholder, attributes: [
                    NSAttributedString.Key.foregroundColor: (UIColor.Gray3?.withAlphaComponent(0.7) ?? .lightGray).cgColor
                ])
        } else {
            shortTextField.text = shortFieldValue
        }
    }

    @IBAction func editingRole(_ sender: PaddingableTextField) {
        updateRecruitingRole?(sender.text ?? "")
    }

    @IBAction func editingNumber(_ sender: PaddingableTextField) {
        updateRecruitingNumber?(sender.text ?? "")
    }
}
