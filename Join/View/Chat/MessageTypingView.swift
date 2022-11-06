//
//  MessageTypingView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit

protocol MessageDelegate: AnyObject {
    func view(_ messageTypingView: MessageTypingView, didSend message: String)
}

class MessageTypingView: UIView {
    static var identifier: String {
        String(describing: self)
    }
    weak var delegate: MessageDelegate?

    @IBOutlet var textField: UITextField!
    @IBOutlet var sendingButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .white
    }

    @IBAction func sendMessage() {
        if !(textField.text ?? "").isEmpty {
            delegate?.view(self, didSend: textField.text!)
            textField.text = ""
        }
    }
}
