//
//  GoNextPageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/23.
//

import UIKit

class GoNextPageCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var button: UIButton!

    var tapHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
        iconImageView.tintColor = .Blue1
        button.backgroundColor = .Blue1?.withAlphaComponent(0.2)
        button.layer.cornerRadius = 8
    }

    func layoutCell(title: String) {
        titleLabel.text = title
    }

    @IBAction func edit(_ sender: UIButton) {
        tapHandler?()
    }
}
