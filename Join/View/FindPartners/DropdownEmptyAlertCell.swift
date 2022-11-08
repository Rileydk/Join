//
//  DropdownEmptyAlertCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/8.
//

import UIKit

class DropdownEmptyAlertCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    var alert = ""

    override func awakeFromNib() {
        layoutViews()
    }

    func layoutViews() {
        alert = "沒有相符的好友"
        titleLabel.text = alert
    }
}
