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

    override func prepareForReuse() {
        super.prepareForReuse()
        button.setTitleColor(.Gray1, for: .normal)
    }

    func layoutCell(title: String) {
        button.setTitle(title, for: .normal)
    }

    func layoutCellForLogout() {
        button.setTitle("Sign out", for: .normal)
        button.setTitleColor(.Red, for: .normal)
    }

    func layoutCellForDeleteAccount() {
        button.setTitle("Delete Account", for: .normal)
        button.setTitleColor(.Red, for: .normal)
    }

    @IBAction func goNextPage(_ sender: UIButton) {
        tapHandler?()
    }
}
