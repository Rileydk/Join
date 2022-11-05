//
//  MessageTypingView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit

class MessageTypingView: UIView {
    static var identifier: String {
        String(describing: self)
    }

    @IBOutlet var textField: UITextField!
    @IBOutlet var sendingButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .white
    }

    @IBAction func sendMessage() {

    }
}
