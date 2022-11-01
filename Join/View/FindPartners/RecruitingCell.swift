//
//  RecruitingCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

protocol RecruitingCellDelegate: AnyObject {
    func cell(_ recruitingCell: RecruitingCell, didSet newRecruit: OpenPosition)
}

class RecruitingCell: TableViewCell {
    @IBOutlet var roleTextField: UITextField!
    @IBOutlet var numberTextField: UITextField!
    @IBOutlet var skillTextField: UITextField!

    weak var delegate: RecruitingCellDelegate?
    var deleteHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        roleTextField.addTarget(self, action: #selector(textFieldDidChanged), for: .editingChanged)
        numberTextField.addTarget(self, action: #selector(textFieldDidChanged), for: .editingChanged)
        skillTextField.addTarget(self, action: #selector(textFieldDidChanged), for: .editingChanged)
    }

    func layoutCell(info: OpenPosition) {
        roleTextField.text = info.role
        numberTextField.text = "\(info.number)"
        skillTextField.text = info.skills
    }

    @objc func textFieldDidChanged(_ textField: UITextField) {
        let newRecruiting = OpenPosition(
            role: roleTextField.text ?? "",
            skills: skillTextField.text ?? "",
            number: (numberTextField.text ?? "").isEmpty
                ? "1" :
                numberTextField.text!
        )
        delegate?.cell(self, didSet: newRecruiting)
    }

    @IBAction func deleteCard() {
        deleteHandler?()
    }
}
