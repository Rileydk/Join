//
//  AddNewLineCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

class AddNewLineSectionCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var addNewButton: UIButton!

    var tapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        addNewButton.backgroundColor = .lightGray
    }

    @IBAction func addNewColumn() {
        tapHandler?()
    }

    func layoutCell(info: ItemInfo) {
        titleLabel.text = info.name
        mustFillSignLabel.isHidden = !info.must
    }
}
