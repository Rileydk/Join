//
//  AppleSignInManager.swift
//  Join
//
//  Created by Riley Lai on 2022/11/24.
//

import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseFirestore
import FirebaseAuth

enum AppleSignInError: Error, LocalizedError {
    case failedToGetUserObject

    var errorDescription: String {
        switch self {
        case .failedToGetUserObject: return "Failed to get user"
        }
    }
}

class AppleSignInManager {
    static let shared = AppleSignInManager()
    private init() {}

    // Get AuthCode
    // gen JWT
    // get refresh token and save in Keychain
    // revoke authorization

    fileprivate var currentNonce: String?

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

    func generateAuthRequest() ->  ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    func signInApple(authorization: ASAuthorization, completion: @escaping (Result<User, Error>) -> Void) {
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

            if let authorizationCode = appleIDCredential.authorizationCode,
               let codeString = String(data: authorizationCode, encoding: .utf8) {
                print("authorization code:", codeString)
            }

            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { [weak self] (_, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let firUser = Auth.auth().currentUser {
                    completion(.success(firUser))
                } else {
                    completion(.failure(AppleSignInError.failedToGetUserObject))
                }
            }
        }
    }
}
