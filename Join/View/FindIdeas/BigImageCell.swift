//
//  BigImageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class BigImageCell: TableViewCell {
    let firebaseManager = FirebaseManager.shared

    @IBOutlet weak var bigImageView: UIImageView!

    func layoutCell(imageURL: URLString) {
        firebaseManager.downloadImage(urlString: imageURL) { [weak self] result in
            switch result {
            case .success(let image):
                self?.bigImageView.image = image
            case .failure(let error):
                print(error)
            }
        }
    }
}
