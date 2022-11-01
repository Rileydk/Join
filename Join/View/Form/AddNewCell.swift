//
//  AddNewCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

class AddNewCell: TableViewCell {
    var tapHandler: (() -> Void)?

    @IBAction func addButton() {
        tapHandler?()
    }

}
