//
//  LoginViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/14.
//

import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseFirestore
import FirebaseAuth

class LoginViewController: BaseViewController {
    let firebaseManager = FirebaseManager.shared
    fileprivate var currentNonce: String?

    @IBOutlet weak var loginProviderStackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .Blue1
        setupProviderLoginView()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    func setupProviderLoginView() {
        let authorizationButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        authorizationButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
        loginProviderStackView.addArrangedSubview(authorizationButton)
    }

    @objc @available(iOS 13, *)
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

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
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { [weak self] (_, error) in
                if let error = error {
                    print(error.localizedDescription)
                    print((error as NSError).userInfo )
                    return
                }
                if let firUser = Auth.auth().currentUser {
                    self?.firebaseManager.firebaseQueue.async {
                        let group = DispatchGroup()
                        group.enter()
                        self?.firebaseManager.lookUpUser(userID: firUser.uid) { result in
                            switch result {
                            case .success(let user):
                                group.leave()
                                // using user id to get interests and load projects
                                print("user: ", user)
                            case .failure(let err):
                                if err as? CommonError == CommonError.noExistUser {
                                    group.leave()
                                } else {
                                    group.leave()
                                    group.notify(queue: .main) {
                                        print(err)
                                    }
                                }
                            }
                        }

                        group.wait()
                        group.enter()
                        self?.firebaseManager.createNewUser(firebaseAuthUser: firUser) { result in
                            switch result {
                            case .success:
                                // go to edit page
                                print()
                            case .failure(let err):
                                print(err)
                            }
                        }
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sing in with Apple errored: \(error)")
    }
}

// MARK: - AS Authorization Controller Presentation Context Providing
extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        self.view.window!
    }
}
