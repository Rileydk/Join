//
//  WorkRecordCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit
import LinkPresentation

class WorkRecordCell: TableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var recordImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        deleteButton.tintColor = .Red
        contentView.backgroundColor = .White
        containerView.layer.cornerRadius = 10
        deleteButton.tintColor = .Red?.withAlphaComponent(0.7)
    }

    func layoutCell(recordImage: UIImage) {
        recordImageView.isHidden = false
        recordImageView.image = recordImage
        recordImageView.layer.masksToBounds = true
        recordImageView.layer.cornerRadius = 10
    }

    func layoutCell(metadata: LPLinkMetadata?) {
        recordImageView.isHidden = true
        if let metadata = metadata, let url = metadata.originalURL {
            let linkView = LPLinkView(url: url)
            linkView.metadata = metadata

            linkView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(linkView)
            NSLayoutConstraint.activate([
                linkView.topAnchor.constraint(equalTo: containerView.topAnchor),
                linkView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                linkView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                linkView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
        } else {
            print("failed")
        }
    }
}
