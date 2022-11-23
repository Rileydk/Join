//
//  WorkRecordCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit

class WorkRecordCell: TableViewCell {
    @IBOutlet weak var recordImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        deleteButton.tintColor = .Red
        contentView.backgroundColor = .White
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func layoutCell(recordImage: UIImage) {
        recordImageView.image = recordImage
    }
}
