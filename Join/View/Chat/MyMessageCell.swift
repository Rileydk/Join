//
//  MyMessageCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit

class MyMessageCell: TableViewCell {
    @IBOutlet weak var messageTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        let inset: CGFloat = 8
        messageTextView.textContainerInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        messageTextView.layer.cornerRadius = 12
        messageTextView.isUserInteractionEnabled = false
        messageTextView.isScrollEnabled = false
    }

    func layoutCell(message: String) {
        messageTextView.text = message
    }
}
