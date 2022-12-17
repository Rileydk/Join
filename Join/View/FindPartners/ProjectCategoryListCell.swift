//
//  ProjectCategoryListCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/22.
//

import UIKit

class ProjectCategoryListCell: TableViewCell {
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func layoutCell(content: String) {
        nameLabel.text = content
        nameLabel.textColor = .Gray1
    }
}
