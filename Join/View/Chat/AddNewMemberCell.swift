//
//  AddNewMemberCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/11.
//

import UIKit

class AddNewMemberCell: TableViewCell {
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!

    var tapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = UIColor.Gray3?.cgColor
        contentView.backgroundColor = .Gray6
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        addButton.layer.cornerRadius = addButton.frame.size.width / 2
    }

    @IBAction func addNewMembers(_ sender: UIButton) {
        tapHandler?()
    }
}
