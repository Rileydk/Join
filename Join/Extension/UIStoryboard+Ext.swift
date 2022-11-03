//
//  UIStoryboard+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

private struct StoryboardCategory {
    static let main = "Main"
    static let findIdeas = "FindIdeas"
    static let findPartners = "FindPartners"
    static let chat = "Chat"
    static let personal = "Personal"
}

extension UIStoryboard {
    static var main: UIStoryboard {
        jStoryboard(name: StoryboardCategory.main)
    }

    static var findIdeas: UIStoryboard {
        jStoryboard(name: StoryboardCategory.findIdeas)
    }

    static var findPartners: UIStoryboard {
        jStoryboard(name: StoryboardCategory.findPartners)
    }

    static var chat: UIStoryboard {
        jStoryboard(name: StoryboardCategory.chat)
    }

    static var personal: UIStoryboard {
        jStoryboard(name: StoryboardCategory.personal)
    }

    private static func jStoryboard(name: String) -> UIStoryboard {
        UIStoryboard(name: name, bundle: nil)
    }
}
