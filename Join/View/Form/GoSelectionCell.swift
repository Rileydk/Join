//
//  goNextPageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit
import TTGTags

class GoSelectionCell: TableViewCell {
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var chevronDownImageView: UIButton!

    let tagView = TTGTextTagCollectionView()
    var tapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        button.backgroundColor = .gray
        button.setTitleColor(.white, for: .normal)
    }

    @IBAction func buttonTapped() {
        tapHandler?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tagView.removeAllTags()
    }

    func layoutCell(info: ItemInfo, tags: [String]? = nil) {
        titleLable.text = info.name
        mustFillSignLabel.isHidden = !info.must

        if let tags = tags {
            addSubview(tagView)
            tagView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tagView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 16),
                tagView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                tagView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                tagView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 16)
            ])

            tagView.alignment = .left
            let style = TTGTextTagStyle()
            style.backgroundColor = .yellow
            style.cornerRadius = 10
            let tagTitles = tags.map {
                TTGTextTag(content: TTGTextTagStringContent(text: $0), style: style)
            }

            tagView.add(tagTitles)
            tagView.reload()
        }
    }
}
