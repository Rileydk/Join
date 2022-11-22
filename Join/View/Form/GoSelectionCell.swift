//
//  goNextPageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit
import TTGTags

protocol GoSelectionCellDelegate: AnyObject {
    func cell(_ cell: GoSelectionCell, didSetDate date: Date)
    func cell(_ cell: GoSelectionCell, didSetLocation location: String)
}

class GoSelectionCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var goNextPageImageView: UIButton!

    let datePicker = UIDatePicker()
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
        mustFillSignLabel.isHidden = !info.must
    }

    func layoutCellWithDatePicker(info: ItemInfo) {
        layoutCell(info: info)

        datePicker.preferredDatePickerStyle = .compact
        // 加上這個會crash
        // datePicker.locale = Locale(identifier: FindPartnersFormSections.datePickerLocale)
        datePicker.calendar = Calendar(identifier: .republicOfChina)
        datePicker.datePickerMode = .dateAndTime
        // 這個沒有作用
        // datePicker.minuteInterval = 15
        datePicker.addTarget(self, action: #selector(updateDate), for: .valueChanged)

        addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            datePicker.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])
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

    @objc func updateDate() {
        delegate?.cell(self, didSetDate: datePicker.date)
    }

    @objc func updateLocation() {
        delegate?.cell(self, didSetLocation: textField.text ?? "")
    }
}
