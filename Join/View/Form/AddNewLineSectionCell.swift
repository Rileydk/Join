//
//  AddNewLineCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

class AddNewLineSectionCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var addNewButton: UIButton!
    @IBOutlet weak var containerStackView: UIStackView!

    var tapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        addNewButton.backgroundColor = .lightGray
    }

    @IBAction func addNewColumn() {
        tapHandler?()
    }

    func layoutCell(info: ItemInfo) {
        titleLabel.text = info.name
        mustFillSignLabel.isHidden = !info.must
    }

    func layoutCell(info: ItemInfo, members: [Member]) {
        layoutCell(info: info)
    }

    func layoutCell(info: ItemInfo, recruiting: [OpenPosition]) {
        layoutCell(info: info)

        if !recruiting.isEmpty {
            recruiting.forEach {
                let positionLabel = UILabel()
                positionLabel.textColor = .black
                positionLabel.font = UIFont.systemFont(ofSize: 16)
                positionLabel.text = "\($0.role) \($0.number) 人"
                containerStackView.insertArrangedSubview(positionLabel, at: 0)
            }
        }
    }
}
