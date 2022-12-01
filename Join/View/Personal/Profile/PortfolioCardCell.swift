//
//  PortfolioCardCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/19.
//

import UIKit

class PortfolioCardCell: CollectionViewCell {
    @IBOutlet weak var workRecordImageView: UIImageView!
    @IBOutlet weak var workNameLabel: UILabel!

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
    }

    func layoutCell(workItem: WorkItem) {
        let indicator = UIActivityIndicatorView()
        contentView.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        guard let firstRecord = workItem.records.first else { return }
        if firstRecord.type == .image {
            workRecordImageView.loadImage(firstRecord.url)
        } else {
            indicator.startAnimating()
            guard let url = URL(string: firstRecord.url) else { return }
            url.getMetadata { [weak self] metadata in
                guard let metadata = metadata else { return }
                metadata.getMetadataImage { image in
                    indicator.stopAnimating()
                    guard let image = image else { return }
                    self?.workRecordImageView.image = image
                }
            }
        }
        workNameLabel.text = workItem.name
    }

}
