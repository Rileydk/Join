//
//  SingleLineInputCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/15.
//

import UIKit

class SingleLineInputCell: TableViewCell {
    enum InputType: String {
        case name = "名稱"
        case email = "Email"
        case workName = "作品名稱"
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    var type: InputType = .name
    var updateName: ((String) -> Void)?
    var updateEmail: ((String) -> Void)?
    var updateWorkName: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .Gray5
        inputTextField.backgroundColor = .Gray5
        inputTextField.addUnderline()
        titleLabel.textColor = .Gray1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func layoutCell(withTitle title: InputType, value: String = "") {
        titleLabel.text = title.rawValue
        inputTextField.text = value
        type = title
    }

    @IBAction func editTextFieldText(_ sender: UITextField) {
        let text = sender.text ?? ""
        switch type {
        case .name:
            updateName?(text)
        case .email:
            updateEmail?(text)
        case .workName:
            updateWorkName?(text)
        }
    }
}
