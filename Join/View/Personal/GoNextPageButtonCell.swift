//
//  GoNextPageButtonCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class GoNextPageButtonCell: TableViewCell {
    @IBOutlet weak var button: UIButton!

    func layoutCell(title: String) {
        button.setTitle(title, for: .normal)
    }
}
