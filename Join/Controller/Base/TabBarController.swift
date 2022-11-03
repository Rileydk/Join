//
//  BaseTabBarController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class TabBarController: UITabBarController {
    enum Tab {
        case findIdeas
        case findPartners
        case chat
        case personal

        var title: String {
            switch self {
            case .findIdeas: return "找點子"
            case .findPartners: return "找夥伴"
            case .chat: return "去聊聊"
            case .personal: return "我的專頁"
            }
        }

        func controller() -> UIViewController {
            var controller: UIViewController

            switch self {
            case .findIdeas:
                controller = UIStoryboard.findIdeas.instantiateInitialViewController()!
            case .findPartners:
                controller = UIStoryboard.findPartners.instantiateInitialViewController()!
            case .chat:
                controller = UIStoryboard.chat.instantiateInitialViewController()!
            case .personal:
                controller = UIStoryboard.personal.instantiateInitialViewController()!
            }

            controller.tabBarItem = tabBarItem()

            return controller
        }

        func tabBarItem() -> UITabBarItem {
            switch self {
            case .findIdeas:
                return UITabBarItem(
                    title: self.title,
                    image: nil,
                    selectedImage: nil
                )
            case .findPartners:
                return UITabBarItem(
                    title: self.title,
                    image: nil,
                    selectedImage: nil
                )
            case .chat:
                return UITabBarItem(
                    title: self.title,
                    image: nil,
                    selectedImage: nil
                )
            case .personal:
                return UITabBarItem(
                    title: self.title,
                    image: nil,
                    selectedImage: nil
                )
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tabs: [Tab] = [.findIdeas, .findPartners, .chat, .personal]
        viewControllers = tabs.map { $0.controller() }
    }
}
