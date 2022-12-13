//
//  ButtonsGroupTableViewCell.swift
//  Join
//
//  Created by Riley Lai on 2022/12/3.
//

import UIKit

class ButtonsGroupTableViewCell: TableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    @IBOutlet weak var thirdButton: UIButton!
    @IBOutlet weak var buttonsContainerView: UIView!
    @IBOutlet weak var buttonsContainerViewBlurEffectView: UIVisualEffectView!
    @IBOutlet weak var arcBackgroundView: UIView!
    @IBOutlet weak var leftDecoratingLine: UIView!
    @IBOutlet weak var rightDecoratingLine: UIView!

    let buttons = Constant.Personal.EntryButtonsGroup.allCases
    var goNextPageHandler: ((Constant.Personal.EntryButtonsGroup) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        firstButton.setTitle(buttons[0].rawValue, for: .normal)
        firstButton.tag = 0
        secondButton.setTitle(buttons[1].rawValue, for: .normal)
        secondButton.tag = 1
        thirdButton.setTitle(buttons[2].rawValue, for: .normal)
        thirdButton.tag = 2

        buttonsContainerView.layer.cornerRadius = 8
        buttonsContainerViewBlurEffectView.layer.masksToBounds = true
        buttonsContainerViewBlurEffectView.layer.cornerRadius = 8
        leftDecoratingLine.backgroundColor = .Gray3?.withAlphaComponent(0.7)
        rightDecoratingLine.backgroundColor = .Gray3?.withAlphaComponent(0.7)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.width / 2
    }

    func layoutCell() {
        guard let name = UserDefaults.standard.string(forKey: UserDefaults.UserKey.userNameKey) else {
            return
        }
        if let imageURL = UserDefaults.standard.string(forKey: UserDefaults.UserKey.userThumbnailURLKey) {
            thumbnailImageView.loadImage(imageURL)
        } else {
            thumbnailImageView.image = UIImage(named: JImages.Icon_UserDefault.rawValue)
        }
        nameLabel.text = name
    }

    @IBAction func goNextPage(_ sender: UIButton) {
        goNextPageHandler?(buttons[sender.tag])
    }
}
