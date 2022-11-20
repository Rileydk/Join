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
        contentView.backgroundColor = .Gray6
        workNameLabel.textColor = .Gray2
        lastUpdateTimeLabel.textColor = .Gray3

        containerView.layer.cornerRadius = 14
        containerView.layer.masksToBounds = true
        shadowView.backgroundColor = .clear
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowRadius = 3
        shadowView.layer.shadowOffset = CGSize(width: 2, height: 2)
        shadowView.layer.shadowColor = UIColor.black.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.layer.shadowPath = UIBezierPath(
            roundedRect: shadowView.bounds,cornerRadius: 14)
            .cgPath
    }

    func layoutCell(workItem: WorkItem) {
        workRecordImageView.loadImage(workItem.records.first!.url)
        workNameLabel.text = workItem.name
        lastUpdateTimeLabel.text = workItem.latestUpdatedTime.formatted
    }

}
