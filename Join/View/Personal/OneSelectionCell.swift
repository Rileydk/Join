//
//  OneSelectionCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit

class OneSelectionCell: TableViewCell {
    @IBOutlet weak var selectionTitleLabel: UILabel!
    @IBOutlet weak var selectImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .Gray5
    }

    func layoutCell(interest: String, isSelected: Bool) {
        selectionTitleLabel.text = interest
        if isSelected {
            selectImageView.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            selectImageView.image = UIImage(systemName: "checkmark.circle")
        }
    }
}
