//
//  MessageTypingSuperview.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit

@IBDesignable
class MessageTypingSuperview: UIView {
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        addMessageTypingView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        addMessageTypingView()
    }

    func addMessageTypingView() {
        if let messageTypingView =
            Bundle(for: MessageTypingView.self)
            .loadNibNamed(MessageTypingView.identifier, owner: nil)?
            .first as? UIView {
            addSubview(messageTypingView)
            messageTypingView.frame = bounds
        }
    }
}
