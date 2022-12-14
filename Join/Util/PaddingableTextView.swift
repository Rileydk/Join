//
//  PaddingableTextView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/22.
//

import UIKit

class PaddingableTextView: UITextView {
    enum ContentType {
        case placeholder
        case userInput
    }

    var contentType: ContentType = .placeholder

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .Gray5
        self.layer.cornerRadius = 8

        let verticalInset: CGFloat = 12
        let horizontalInset: CGFloat = 15
        self.textContainer.lineFragmentPadding = 0
        self.textContainerInset = .init(
            top: verticalInset, left: horizontalInset,
            bottom: verticalInset, right: horizontalInset)
    }
}
