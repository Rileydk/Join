//
//  BottomLinedTextField.swift
//  Join
//
//  Created by Riley Lai on 2022/11/21.
//

import UIKit

class BottomLinedTextField: UITextField {

    var bottomLine = UIView()

    override func awakeFromNib() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.borderStyle = .none
        bottomLine = .init(frame: .zero)
        bottomLine.backgroundColor = UIColor.Gray1
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLine)

        NSLayoutConstraint.activate([
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

}
