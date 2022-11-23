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
        case projectName = "專案名稱"

        var textFieldValue: String {
            switch self {
            case .projectName: return "請輸入專案名稱"
            default: return ""
            }
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputTextField: PaddingableTextField!
    var type: InputType = .name
    var updateName: ((String) -> Void)?
    var updateEmail: ((String) -> Void)?
    var updateWorkName: ((String) -> Void)?
    var updateProjectName: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
        titleLabel.textColor = .Gray1
        inputTextField.addTarget(self, action: #selector(textChanged123), for: .editingChanged)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func layoutCell(withTitle title: InputType, value: String) {
        titleLabel.text = title.rawValue
        inputTextField.text = value
        inputTextField.attributedPlaceholder = NSAttributedString(
            string: Constant.FindPartners.projectNamePlaceholder, attributes: [
                NSAttributedString.Key.foregroundColor: (UIColor.Gray3?.withAlphaComponent(0.7) ?? .lightGray).cgColor
            ])
        type = title
    }

    @objc func textChanged123(sender: UITextField) {
        let text = sender.text ?? ""
        switch type {
        case .name:
            updateName?(text)
        case .email:
            updateEmail?(text)
        case .workName:
            updateWorkName?(text)
        case .projectName:
            updateProjectName?(text)
        }
    }

    @IBAction func editTextFieldText(_ sender: UITextField) {
        var text = sender.text ?? ""
        text = text.trimmingCharacters(in: .whitespaces)
        switch type {
        case .name:
            updateName?(text)
        case .email:
            updateEmail?(text)
        case .workName:
            updateWorkName?(text)
        case .projectName:
            updateProjectName?(text)
        }
    }
}
