//
//  JGProgressWrapper.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import Foundation
import JGProgressHUD

class JProgressHUD {
    static let shared = JProgressHUD()
    private init() {}

    let hud = JGProgressHUD(style: .dark)
    // TODO: - 沒有正常顯示？
//    var view: UIView { SceneDelegate.shared.window!.rootViewController!.view }

    func showSuccess(text: String = "Success", view: UIView, completion: (() -> Void)? = nil) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showSuccess(text: text, view: view, completion: completion)
            }
            return
        }
        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud.textLabel.text = text
        hud.show(in: view)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.hud.dismiss()
            completion?()
        }
    }

    func showFailure(text: String = "Failed", view: UIView, completion: (() -> Void)? = nil) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showFailure(text: text, view: view, completion: completion)
            }
            return
        }
        hud.indicatorView = JGProgressHUDErrorIndicatorView()
        hud.textLabel.text = text
        hud.show(in: view)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.hud.dismiss()
            completion?()
        }
    }

    func showLoading(text: String = "Loading...", view: UIView) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showLoading(text: text, view: view)
            }
            return
        }
        hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()
        hud.textLabel.text = text
        hud.show(in: view)
    }

    func showSaving(text: String = "Saving...", view: UIView) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showSaving(text: text, view: view)
            }
            return
        }
        hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()
        hud.vibrancyEnabled = true
        hud.textLabel.text = text
        hud.show(in: view)
    }

    func dismiss() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.dismiss()
            }
            return
        }
        hud.dismiss()
    }
}
