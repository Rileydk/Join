//
//  MessageTypingSuperview.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit

protocol MessageSuperviewDelegate: AnyObject {
    func view(_ messageTypingSuperview: MessageTypingSuperview, didSend message: String)
}

@IBDesignable
class MessageTypingSuperview: UIView {
    weak var delegate: MessageSuperviewDelegate?

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
            .first as? MessageTypingView {

            messageTypingView.backgroundColor = .Blue1
            addSubview(messageTypingView)
            messageTypingView.frame = bounds
            messageTypingView.delegate = self
        }
    }
}

// MARK: - Message Delegate
extension MessageTypingSuperview: MessageDelegate {
    func view(_ messageTypingView: MessageTypingView, didSend message: String) {
        delegate?.view(self, didSend: message)
    }
}
