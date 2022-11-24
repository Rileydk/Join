//
//  PaddingableLabel.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import UIKit

class PaddingableLabel: UILabel {

    private var padding = UIEdgeInsets.zero

    @IBInspectable
    var paddingLeft: CGFloat {
        get { padding.left }
        set { padding.left = newValue}
    }

    @IBInspectable
    var paddingRight: CGFloat {
        get { padding.right }
        set { padding.right = newValue}
    }

    @IBInspectable
    var paddingTop: CGFloat {
        get { padding.top }
        set { padding.top = newValue}
    }

    @IBInspectable
    var paddingBottom: CGFloat {
        get { padding.bottom }
        set { padding.bottom = newValue}
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var rect = super.textRect(forBounds: bounds.inset(by: padding), limitedToNumberOfLines: numberOfLines)
        rect.origin.x    -= padding.left
        rect.origin.y    -= padding.top
        rect.size.width  += padding.right + padding.left
        rect.size.height += padding.top + padding.bottom
        return rect
    }
}
