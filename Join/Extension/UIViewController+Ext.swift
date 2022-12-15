//
//  UIViewController+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/12/15.
//

import Foundation
import UIKit

extension UIViewController {
    enum NavBarMode {
        case light
        case dark
    }

    func setNavBarAppearance(to mode: NavBarMode) {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()

        let backIcon = UIImage(named: JImages.Icon_24px_Back.rawValue)
        navBarAppearance.setBackIndicatorImage(backIcon, transitionMaskImage: backIcon)

        switch mode {
        case .light:
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.Gray1 ?? .gray]
            navBarAppearance.backgroundColor = .Gray6
            navigationController?.navigationBar.tintColor = .Gray1
        case .dark:
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.White ?? .white]
            navBarAppearance.backgroundColor = .Blue1
            navigationController?.navigationBar.tintColor = .White
        }
        navBarAppearance.shadowColor = nil
        navBarAppearance.shadowImage = UIImage()
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
}
