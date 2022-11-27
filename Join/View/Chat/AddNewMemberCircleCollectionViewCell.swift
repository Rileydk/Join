//
//  AddNewMemberCircleCollectionViewCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/27.
//

import UIKit

class AddNewMemberCircleCollectionViewCell: CollectionViewCell {

    @IBOutlet weak var addNewMemberButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        addNewMemberButton.layer.borderWidth = 1
        addNewMemberButton.layer.borderColor = UIColor.Gray3?.cgColor
        addNewMemberButton.isUserInteractionEnabled = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        addNewMemberButton.layer.cornerRadius = addNewMemberButton.frame.width / 2
    }

    @IBAction func addNewMember(_ sender: UIButton) {
    }
}
