//
//  DataPickerCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/23.
//

import UIKit

class DatePickerCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var noteLabel: UILabel!

    var updateDateHandler: ((Date) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
        datePicker.minimumDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        datePicker.setValue(UIColor.Gray2, forKey: "textColor")
        datePicker.tintColor = .Blue1
    }

    func layoutCell(item: ItemInfo, deadline: Date?) {
        titleLabel.text = item.name
        noteLabel.text = item.note ?? ""
        if let deadline = deadline {
            datePicker.date = deadline
        }
    }

    @IBAction func updateDate(_ sender: UIDatePicker) {
        updateDateHandler?(sender.date)
    }

}
