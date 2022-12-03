//
//  MyMasterpieceTableViewCell.swift
//  Join
//
//  Created by Riley Lai on 2022/12/2.
//

import UIKit

class MyMasterpieceTableViewCell: TableViewCell {
    @IBOutlet weak var myMasterpieceImageView: UIImageView!

    func layoutCell(workRecordWithImage: WorkRecordWithImage) {
        guard let image = workRecordWithImage.image else { return }
        self.myMasterpieceImageView.image = image
    }

    func layoutCell(workRecord: WorkRecord) {
        let indicator = UIActivityIndicatorView()
        contentView.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        myMasterpieceImageView.translatesAutoresizingMaskIntoConstraints = false
        if workRecord.type == .image {
            FirebaseManager.shared.downloadImage(urlString: workRecord.url) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let image):
                    NSLayoutConstraint.activate([
                        self.myMasterpieceImageView.widthAnchor.constraint(equalTo: self.myMasterpieceImageView.heightAnchor, multiplier: image.size.width / image.size.height)
                    ])
                    self.myMasterpieceImageView.image = image
    //                recordImage = image
                case .failure(let err):
                    break
                }
            }
//            myMasterpieceImageView.loadImage(workRecord.url)
        } else {
            indicator.startAnimating()
            guard let url = URL(string: workRecord.url) else { return }
            url.getMetadata { [weak self] metadata in
                guard let self = self, let metadata = metadata else { return }
                metadata.getMetadataImage { image in
                    indicator.stopAnimating()
                    guard let image = image else { return }
                    NSLayoutConstraint.activate([
                        self.myMasterpieceImageView.widthAnchor.constraint(equalTo: self.myMasterpieceImageView.heightAnchor, multiplier: image.size.width / image.size.height)
                    ])
                    self.myMasterpieceImageView.image = image
                }
            }
        }
    }

}
