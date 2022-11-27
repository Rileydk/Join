//
//  PortfolioCardCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/19.
//

import UIKit

class PortfolioCardCell: CollectionViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var workRecordImageView: UIImageView!
    @IBOutlet weak var workNameLabel: UILabel!
    @IBOutlet weak var lastUpdateTimeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.backgroundColor = UIColor.clear.cgColor
        layer.masksToBounds = false
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowColor = UIColor.Gray1?.cgColor

        contentView.backgroundColor = .White
        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = .Gray6
        workRecordImageView.clipsToBounds = true
        workRecordImageView.layer.cornerRadius = 8
        workRecordImageView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        workNameLabel.textColor = .Gray2
        lastUpdateTimeLabel.textColor = .Gray3
    }

    func layoutCell(workItem: WorkItem) {
        workRecordImageView.loadImage(workItem.records.first!.url)
        workNameLabel.text = workItem.name
        lastUpdateTimeLabel.text = workItem.latestUpdatedTime.formatted
    }

}
