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
        case location = "地點"

        var placeholder: String {
            switch self {
            case .name: return "請輸入您的名稱"
            case .email: return "請輸入 email"
            case .workName: return "請輸入作品名稱"
            case .projectName: return "請輸入專案名稱"
            case .location: return "線上/地址"
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
    var updateLocation: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
        titleLabel.textColor = .Gray1
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func layoutCell(withTitle type: InputType, value: String) {
        titleLabel.text = type.rawValue
        inputTextField.text = value
        inputTextField.attributedPlaceholder = NSAttributedString(
            string: type.placeholder, attributes: [
                NSAttributedString.Key.foregroundColor: (UIColor.Gray3?.withAlphaComponent(0.7) ?? .lightGray)
            ])
        self.type = type
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
        case .location:
            updateLocation?(text)
        }
    }
}
