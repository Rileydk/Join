//
//  DetailTitleHeaderView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class DetailTitleHeaderView: TableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var shareLinkButton: UIButton!
    @IBOutlet weak var bookMarkButton: UIButton!

    func layoutHeaderView(title: String) {
        titleLabel.text = title
    }
}
