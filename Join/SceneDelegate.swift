//
//  SceneDelegate.swift
//  Join
//
//  Created by Riley Lai on 2022/10/28.
//

import UIKit
import FirebaseAuth

// swiftlint:disable line_length
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    static let scene = UIApplication.shared.connectedScenes.first
    static let shared = scene!.delegate as! SceneDelegate

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure
        // and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property
        // will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new
        // (see `application:configurationForConnectingSceneSession` instead).

        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)

        let mainStoryboard = UIStoryboard(name: StoryboardCategory.main.rawValue, bundle: nil)
        if Auth.auth().currentUser == nil || UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) == nil {
            guard let loginVC = mainStoryboard.instantiateViewController(
                withIdentifier: LoginViewController.identifier
                ) as? LoginViewController else {
                fatalError("Cannot instantiate log in vc")
            }
            window?.rootViewController = loginVC
            window?.makeKeyAndVisible()
        } else {
            guard let tabBarController = mainStoryboard.instantiateViewController(
                withIdentifier: TabBarController.identifier
                ) as? TabBarController else {
                fatalError("Cannot load tab bar controller")
            }
            tabBarController.selectedIndex = 0
            window?.rootViewController = tabBarController
            window?.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that
        // can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded
        // (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks
        // that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources,
        // and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
