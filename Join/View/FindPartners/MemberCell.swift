//
//  MemberCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

class MemberCell: TableViewCell {
    @IBOutlet var friendNameTextField: UITextField!
    @IBOutlet var roleTextField: UITextField!
    @IBOutlet var skillTextField: UITextField!

    var deleteHandler: (() -> Void)?

    func layoutCell(info: Member) {
        // TODO: - 未來要改成用 id 搜尋後，取得名字
        friendNameTextField.text = info.id
        roleTextField.text = info.role
        skillTextField.text = info.skills
    }

    @IBAction func deleteCard() {

    }
}
