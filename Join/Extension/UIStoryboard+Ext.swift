//
//  UIStoryboard+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

enum StoryboardCategory: String {
    case main = "Main"
    case findIdeas = "FindIdeas"
    case findPartners = "FindPartners"
    case chat = "Chat"
    case personal = "Personal"
}

extension UIStoryboard {
    static var main: UIStoryboard {
        jStoryboard(name: StoryboardCategory.main.rawValue)
    }

    static var findIdeas: UIStoryboard {
        jStoryboard(name: StoryboardCategory.findIdeas.rawValue)
    }

    static var findPartners: UIStoryboard {
        jStoryboard(name: StoryboardCategory.findPartners.rawValue)
    }

    static var chat: UIStoryboard {
        jStoryboard(name: StoryboardCategory.chat.rawValue)
    }

    static var personal: UIStoryboard {
        jStoryboard(name: StoryboardCategory.personal.rawValue)
    }

    private static func jStoryboard(name: String) -> UIStoryboard {
        UIStoryboard(name: name, bundle: nil)
    }
}
