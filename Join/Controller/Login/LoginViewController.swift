//
//  LoginViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/14.
//

import UIKit
import AuthenticationServices

class LoginViewController: BaseViewController {
    let firebaseManager = FirebaseManager.shared
    let appleSignInManager = AppleSignInManager.shared

    @IBOutlet weak var loginProviderStackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .Blue1
        setupProviderLoginView()
    }

    func setupProviderLoginView() {
        let authorizationButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        authorizationButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
        loginProviderStackView.addArrangedSubview(authorizationButton)
    }

    @objc @available(iOS 13, *)
    func startSignInWithAppleFlow() {
        let request = appleSignInManager.generateAuthRequest()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

// MARK: - AS Authorization Controller Delegate
extension LoginViewController: ASAuthorizationControllerDelegate {
    @available(iOS 13, *)
    // swiftlint:disable line_length
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        appleSignInManager.signInApple(authorization: authorization) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let firUser):
                self.firebaseManager.firebaseQueue.async {
                    var shouldContinue = true
                    let group = DispatchGroup()
                    group.enter()
                    self.firebaseManager.lookUpUser(userID: firUser.uid) { result in
                        switch result {
                        case .success(let user):
                            UserDefaults.standard.setValue(user.id, forKey: UserDefaults.UserKey.uidKey)
                            UserDefaults.standard.setValue(user.thumbnailURL, forKey: UserDefaults.UserKey.userThumbnailURLKey)
                            UserDefaults.standard.setValue(user.name, forKey: UserDefaults.UserKey.userNameKey)
                            UserDefaults.standard.setValue(user.interests, forKey: UserDefaults.UserKey.userInterestsKey)

                            shouldContinue = false
                            group.leave()
                            group.notify(queue: .main) {
                                let mainStoryboard = UIStoryboard(name: StoryboardCategory.main.rawValue, bundle: nil)
                                guard let tabBarController = mainStoryboard.instantiateViewController(
                                    withIdentifier: TabBarController.identifier
                                ) as? TabBarController else {
                                    fatalError("Cannot load tab bar controller")
                                }
                                tabBarController.selectedIndex = 0
                                tabBarController.modalPresentationStyle = .fullScreen

                                JProgressHUD.shared.showSuccess(view: self.view) {
                                    self.present(tabBarController, animated: false)
                                }
                            }
                        case .failure(let err):
                            if err as? CommonError == CommonError.noExistUser {
                                group.leave()
                            } else {
                                shouldContinue = false
                                group.leave()
                                group.notify(queue: .main) {
                                    JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                                }
                            }
                        }
                    }

                    group.wait()
                    guard shouldContinue else { return }
                    group.enter()
                    let newUser = JUser(id: firUser.uid, name: firUser.displayName ?? "",
                                        email: firUser.email ?? "",
                                        thumbnailURL: firUser.photoURL != nil
                                        ? String(describing: firUser.photoURL)
                                        : FindPartnersFormSections.placeholderImageURL)
                    self.firebaseManager.set(user: newUser) { result in
                        switch result {
                        case .success(let user):
                            UserDefaults.standard.setValue(user.id, forKey: UserDefaults.UserKey.uidKey)

                            group.notify(queue: .main) {
                                let storyboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                                guard let profileEditVC = storyboard.instantiateViewController(
                                    withIdentifier: PersonalProfileEditViewController.identifier
                                ) as? PersonalProfileEditViewController else {
                                    fatalError("Cannot instantiate profile edit vc")
                                }
                                profileEditVC.user = user

                                let navController = UINavigationController(rootViewController: profileEditVC)
                                navController.modalPresentationStyle = .fullScreen

                                JProgressHUD.shared.showSuccess(view: self.view) {
                                    self.present(navController, animated: false)
                                }
                            }

                        case .failure(let err):
                            group.notify(queue: .main) {
                                JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                            }
                        }
                    }
                }
            case .failure(let err):
                JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        JProgressHUD.shared.showFailure(text: error.localizedDescription, view: self.view)
    }
}

// MARK: - AS Authorization Controller Presentation Context Providing
extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        self.view.window!
    }
}
