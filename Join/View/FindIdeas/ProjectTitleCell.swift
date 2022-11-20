//
//  RecruitingTitleCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import UIKit

class ProjectTitleCell: TableViewCell {
    @IBOutlet weak var recruitingTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func layoutCell(title: String?) {
        recruitingTitleLabel.text = title ?? ""
    }
}
