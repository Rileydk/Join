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

    var alertHandler: ((UIAlertController) -> Void)?

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

    func layoutCell(url: URL) {
        recordImageView.isHidden = true
        let indicator = UIActivityIndicatorView()
        containerView.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        indicator.startAnimating()
        url.getMetadata { [weak self] metadata in
            guard let self = self else { return }
            if let metadata = metadata, let url = metadata.originalURL {
                let linkView = LPLinkView(url: url)
                linkView.metadata = metadata
                indicator.stopAnimating()

                linkView.translatesAutoresizingMaskIntoConstraints = false
                self.containerView.addSubview(linkView)
                NSLayoutConstraint.activate([
                    linkView.topAnchor.constraint(equalTo: self.containerView.topAnchor),
                    linkView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
                    linkView.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
                    linkView.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
                ])
            } else {
                indicator.stopAnimating()
                let alert = UIAlertController(title: Constant.Common.notValidURL, message: nil, preferredStyle: .alert)
                let action = UIAlertAction(title: Constant.Common.ok, style: .default)
                alert.addAction(action)
                self.alertHandler?(alert)
            }
        }


    }
}
