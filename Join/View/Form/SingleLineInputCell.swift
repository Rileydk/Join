//
//  SingleLineInputCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/15.
//

import UIKit

class SingleLineInputCell: TableViewCell {
    enum InputType: String {
        case name = "Name"
        case email = "Email"
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    var type: InputType = .name
    var updateName: ((String) -> Void)?
    var updateEmail: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func layoutCell(withTitle title: InputType, value: String) {
        titleLabel.text = title.rawValue
        inputTextField.text = value
        type = title
    }

    @IBAction func editTextFieldText(_ sender: UITextField) {
        if type == .name {
            updateName?(sender.text ?? "")
        } else {
            updateEmail?(sender.text ?? "")
        }
    }
}
