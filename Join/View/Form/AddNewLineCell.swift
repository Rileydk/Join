//
//  AddNewLineCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

class AddNewLineCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var addNewButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        addNewButton.backgroundColor = .lightGray
    }

    @IBAction func addNewColumn() {
    }

    func layoutCell(info: ItemInfo) {
        titleLabel.text = info.name
        mustFillSignLabel.isHidden = !info.must
    }
}
