//
//  DetailTitleHeaderView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class DetailTitleHeaderView: TableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .Gray6
    }

    func layoutHeaderView(title: String) {
        titleLabel.text = title
    }
}
