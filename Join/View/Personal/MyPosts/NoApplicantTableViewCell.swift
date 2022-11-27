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
        emptyAlertLabel.textColor = .Gray3?.withAlphaComponent(0.7)
        backgroundColor = .White
        contentView.backgroundColor = .Gray3?.withAlphaComponent(0.3)
        contentView.layer.borderWidth = 12
        contentView.layer.borderColor = UIColor.White?.cgColor
    }
}
