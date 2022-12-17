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

    func layoutCell(
        longFieldTitle: String, longFieldValue: String,
        shortFieldTitle: String, shortFieldValue: String) {
        longTextFieldTitleLabel.text = longFieldTitle
        longTextField.text = longFieldValue
        longTextField.attributedPlaceholder = NSAttributedString(
            string: Constant.FindPartners.recruitingRolePlaceholder, attributes: [
                NSAttributedString.Key.foregroundColor: (
                    UIColor.Gray3?.withAlphaComponent(0.7) ??
                    .lightGray).cgColor
            ])

        shortTextFieldTitleLabel.text = shortFieldTitle
        shortTextField.text = shortFieldValue.isEmpty ? "1" : shortFieldValue
    }

    @IBAction func editingRole(_ sender: PaddingableTextField) {
        var text = sender.text ?? ""
        text = text.trimmingCharacters(in: .whitespaces)
        updateRecruitingRole?(text)
    }

    @IBAction func editingNumber(_ sender: PaddingableTextField) {
        var text = sender.text ?? ""
        text = text.trimmingCharacters(in: .whitespaces)
        updateRecruitingNumber?(text)
    }
}
