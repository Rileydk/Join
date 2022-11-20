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
        bigImageView.loadImage(imageURL)
    }
}
