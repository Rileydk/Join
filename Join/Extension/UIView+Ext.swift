//
//  UIView+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

extension UIView {
    func addUnderline(color: UIColor = .black, width: CGFloat = 1) {
        let underline = UIView(
            frame: CGRect(
                x: self.frame.minX, y: self.frame.maxY,
                width: self.frame.maxX - self.frame.minX, height: width
            )
        )
        underline.backgroundColor = color
        self.superview?.addSubview(underline)
    }
}
