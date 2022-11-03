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
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var chevronDownImageView: UIButton!

    let tagView = TTGTextTagCollectionView()
    let datePicker = UIDatePicker()
    let textField = UITextField()
    var tapHandler: (() -> Void)?
    weak var delegate: GoSelectionCellDelegate?

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

    func layoutCell(info: ItemInfo) {
        titleLable.text = info.name
        mustFillSignLabel.isHidden = !info.must
    }

    func layoutCell(info: ItemInfo, tags: [String]) {
        layoutCell(info: info)
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
