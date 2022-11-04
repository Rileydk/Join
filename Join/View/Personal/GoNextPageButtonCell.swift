//
//  GoNextPageButtonCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class GoNextPageButtonCell: TableViewCell {
    @IBOutlet weak var button: UIButton!

    var tapHandler: (() -> Void)?

    func layoutCell(title: String) {
        button.setTitle(title, for: .normal)
    }

    @IBAction func goNextPage(_ sender: UIButton) {
        tapHandler?()
    }
}
