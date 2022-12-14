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

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .Gray6
    }

    func layoutCell(imageURL: URLString) {
        bigImageView.loadImage(imageURL)
    }
}
