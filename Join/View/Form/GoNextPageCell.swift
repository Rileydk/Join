//
//  goNextPageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class GoNextPageCell: TableViewCell {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var chevronRightImageView: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        button.backgroundColor = .gray
        button.setTitleColor(.white, for: .normal)
    }

    func layoutCell(info: ItemInfo) {
        button.setTitle(info.name, for: .normal)
    }
}
