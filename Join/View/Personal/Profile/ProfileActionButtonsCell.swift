//
//  ProfileActionButtonsCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/19.
//

import UIKit

class ProfileActionButtonsCell: CollectionViewCell {
    @IBOutlet weak var editProfileButton: UIButton!

    var editProfileHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        editProfileButton.layer.cornerRadius = 8
        editProfileButton.setTitleColor(.Gray2, for: .normal)
        editProfileButton.backgroundColor = .Gray4
    }

    @IBAction func editProfile(_ sender: Any) {
        editProfileHandler?()
    }

    func layoutCell(backgroundColor: UIColor) {
        contentView.backgroundColor = backgroundColor
    }
}
