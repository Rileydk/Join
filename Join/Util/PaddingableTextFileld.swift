//
//  PaddingableTextFileld.swift
//  Join
//
//  Created by Riley Lai on 2022/11/22.
//

import UIKit

class PaddingableTextField: UITextField {
    let verticalInset: CGFloat = 5
    let horizontalInset: CGFloat = 15
    var padding: UIEdgeInsets {
        UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.borderStyle = .none
        self.backgroundColor = .Gray5
        self.layer.cornerRadius = 8
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }
}
