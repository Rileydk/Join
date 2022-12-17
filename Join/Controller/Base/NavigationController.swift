//
//  NavigationController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.White ?? .white]
        navBarAppearance.backgroundColor = .Blue1
        navBarAppearance.shadowColor = nil
        navBarAppearance.shadowImage = UIImage()
        self.navigationBar.standardAppearance = navBarAppearance
        self.navigationBar.scrollEdgeAppearance = navBarAppearance
        self.navigationBar.tintColor = .White
    }
}
