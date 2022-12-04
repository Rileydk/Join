//
//  GoNextPageTableViewCell.swift
//  Join
//
//  Created by Riley Lai on 2022/12/4.
//

import UIKit

class GoNextPageTableViewCell: TableViewCell {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var rightArrowImageView: UIImageView!

    var tapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        button.backgroundColor = .Blue1?.withAlphaComponent(0.8)

        button.setTitleColor(.White, for: .normal)
        rightArrowImageView.tintColor = .White
    }

    func layoutCell(title: String) {
        button.setTitle(title, for: .normal)
    }

    @IBAction func goNextPage(_ sender: Any) {
        tapHandler?()
    }
}
