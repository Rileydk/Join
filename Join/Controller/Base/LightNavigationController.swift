//
//  LightNavigationController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/22.
//

import UIKit

class LightNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.Gray1 ?? .gray]
        navBarAppearance.backgroundColor = .White
        self.navigationBar.standardAppearance = navBarAppearance
        self.navigationBar.scrollEdgeAppearance = navBarAppearance
        self.navigationBar.tintColor = .Gray1
    }
}
