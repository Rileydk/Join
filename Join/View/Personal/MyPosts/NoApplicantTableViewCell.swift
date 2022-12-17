//
//  NoApplicantTableViewCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/27.
//

import UIKit

class NoApplicantTableViewCell: TableViewCell {
    @IBOutlet weak var emptyAlertLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        emptyAlertLabel.text = Constant.FindIdeas.noApplicantAlertMessage
        emptyAlertLabel.textColor = .Gray3?.withAlphaComponent(0.9)
        contentView.backgroundColor = .Gray6
    }
}
