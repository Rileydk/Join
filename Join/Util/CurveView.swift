//
//  CurveView.swift
//  Join
//
//  Created by Riley Lai on 2022/12/3.
//

import UIKit

class CurveView: UIView {
    var firstTimeLayout = true

    override func layoutSubviews() {
        super.layoutSubviews()

        if firstTimeLayout {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: self.frame.height))
            path.addQuadCurve(
                to: CGPoint(x: self.frame.width,
                            y: self.frame.height),
                controlPoint: CGPoint(x: self.frame.width / 2,
                                      y: self.frame.height + 50))
            path.close()
            let layer = CAShapeLayer()
            layer.path = path.cgPath
            layer.fillColor = self.backgroundColor?.cgColor
            self.layer.insertSublayer(layer, at: 0)
            firstTimeLayout = false
        }
    }
}
