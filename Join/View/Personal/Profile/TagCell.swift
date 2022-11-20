//
//  TagCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import UIKit

class TagCell: CollectionViewCell {
    @IBOutlet weak var tagLabel: PaddingableLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        tagLabel.layer.backgroundColor = (UIColor.Yellow2 ?? .lightGray).cgColor
        tagLabel.textColor = .Gray3
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tagLabel.layer.cornerRadius = tagLabel.frame.size.height / 2
    }

    func layoutCell(item: String) {
        tagLabel.text = item
    }
}
