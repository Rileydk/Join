//
//  UIColor+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/11/13.
//

import Foundation
import UIKit

// swiftlint:disable identifier_name
enum JColor: String {
    case Gray1
    case Gray2
    case Gray3
    case Gray4
    case Gray5
    case Gray6
    case Blue1
    case Blue2
    case Blue3
    case Blue4
    case Red
    case Yellow
}

extension UIColor {
    static let Gray1 = JColor(.Gray1)
    static let Gray2 = JColor(.Gray2)
    static let Gray3 = JColor(.Gray3)
    static let Gray4 = JColor(.Gray4)
    static let Gray5 = JColor(.Gray5)
    static let Gray6 = JColor(.Gray6)
    static let Blue1 = JColor(.Blue1)
    static let Blue2 = JColor(.Blue2)
    static let Blue3 = JColor(.Blue3)
    static let Blue4 = JColor(.Blue4)
    static let Red = JColor(.Red)
    static let Yellow = JColor(.Yellow)

    static func JColor(_ color: JColor) -> UIColor? {
        UIColor(named: color.rawValue)
    }
}
