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

typealias ClientSecretToken = String
typealias JWTTokent = String

class AppleSignInManager {
    enum AppleSignInError: Error, LocalizedError {
        case failedToGetUserObject

        var errorDescription: String {
            switch self {
            case .failedToGetUserObject: return "Failed to get user"
            }
        }
    }

    static let shared = AppleSignInManager()
    private init() {}

    let keychainManager = KeychainManager.shared

    // Get AuthCode
    // gen JWT
    // get refresh token and save in Keychain
    // revoke authorization
    // deleteUser

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
                keychainManager.save(stringContent: codeString,
                                     by: UserDefaults.AppleSignInKey.authorizationCodeKey)
            }

            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (_, error) in
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

    func revokeCredential() {
        generateClientSecretToken()
    }

    func generateClientSecretToken() -> JWTTokent? {
        // completion: @escaping (Result<ClientSecretToken, Error>) -> Void
        struct Header: Encodable {
            let alg = "ES256"
            let kid = AppleAuthConfig.p8KeyID.rawValue
        }

        struct Payload: Encodable {
            let iss = AppleAuthConfig.teamID.rawValue
            let iat = Date().millisecondsSince1970
            let exp = Date().millisecondsSince1970 + 12000
            let aud = "https://appleid.apple.com"
            let sub = AppleAuthConfig.bundleID.rawValue
        }

        var privateContent = ""
        if let filePath = Bundle.main.path(forResource: AppleAuthConfig.privateKeyFileName.rawValue, ofType: "p8") {
            do {
                privateContent = try String(contentsOfFile: filePath)
            } catch {
                print("decode failed")
            }
        } else {
            print("file path is nil")
        }

        let privateKey = SymmetricKey(data: Data(privateContent.utf8))

        guard let headerJSONData = try? JSONEncoder().encode(Header()) else {
            print("failed to encode header")
            return nil
        }
        let headerBase64String = headerJSONData.urlSafeBase64EncodedString()

        guard let payloadJSONData = try? JSONEncoder().encode(Payload()) else {
            print("failed to encode payload")
            return nil
        }
        let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()

        let jwt = Data((headerBase64String + "." + payloadBase64String).utf8)
        let signature = HMAC<SHA256>.authenticationCode(for: jwt, using: privateKey)
        let signatureBase64String = Data(signature).urlSafeBase64EncodedString()

        let signedJWT = [headerBase64String, payloadBase64String, signatureBase64String]
            .joined(separator: ".")
        return signedJWT
    }

    func getRefreshToken() {
        let url = URL(string: "https://appleid.apple.com/auth/token")!
        //        var request = URLRequest(url: )
    }
}
