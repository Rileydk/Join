//
//  BottomLinedTextView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/21.
//

import UIKit

class BottomLinedTextView: UITextView {

    var bottomLine = UIView()

    override func awakeFromNib() {
        self.textContainer.lineFragmentPadding = 0
        self.textColor = .Red
        self.translatesAutoresizingMaskIntoConstraints = false
        bottomLine = .init(frame: .zero)
        bottomLine.backgroundColor = UIColor.Gray1
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLine)

        NSLayoutConstraint.activate([
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: -1)
        ])
    }

}
