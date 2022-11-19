//
//  SelfIntroductionCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/19.
//

import UIKit

class SelfIntroductionCell: CollectionViewCell {
    @IBOutlet weak var introductionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        introductionLabel.textColor = .Gray3
        introductionLabel.textAlignment = .center
    }

    func layoutCell(content: String) {
        introductionLabel.text = content
    }
}
