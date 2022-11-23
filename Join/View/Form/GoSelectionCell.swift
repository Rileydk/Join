//
//  goNextPageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

protocol GoSelectionCellDelegate: AnyObject {
//    func cell(_ cell: GoSelectionCell, didSetDate date: Date)
    func cell(_ cell: GoSelectionCell, didSetLocation location: String)
}

class GoSelectionCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var goNextPageImageView: UIButton!
    @IBOutlet weak var noteLabel: UILabel!

    let textField = UITextField()
    var tapHandler: (() -> Void)?
    weak var delegate: GoSelectionCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
        button.backgroundColor = .Blue1?.withAlphaComponent(0.2)
        button.layer.cornerRadius = 8
    }

    @IBAction func buttonTapped() {
        tapHandler?()
    }
    func layoutCell(info: ItemInfo) {
        titleLabel.text = info.name
        subtitleLabel.text = info.subtitle ?? ""
        noteLabel.text = info.note ?? ""
        mustFillSignLabel.isHidden = !info.must
    }

    func layoutCellWithTextField(info: ItemInfo) {
        layoutCell(info: info)

        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.addTarget(self, action: #selector(updateLocation), for: .editingChanged)

        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])
    }

    @objc func updateLocation() {
        delegate?.cell(self, didSetLocation: textField.text ?? "")
    }
}
