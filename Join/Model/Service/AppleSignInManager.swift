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
import SwiftJWT

typealias ClientSecretToken = String
typealias JWTToken = String

struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int64
    let refreshToken: String
    let idToken: String
}

class AppleSignInManager {
    enum AppleSignInError: Error, LocalizedError {
        case failedToGetUserObject
        case responseError
        case decodeFailed
        case noValidJWT

        var errorDescription: String {
            switch self {
            case .failedToGetUserObject: return "Failed to get user"
            case .responseError: return "Get refresh token response error"
            case .decodeFailed: return "Decode failed"
            case .noValidJWT: return "No valid JWT"
            }
        }
    }

    struct UserInitInfo {
        var id: String
        var name: String
        var email: String
        var thumbnail: URLString?
    }

    static let shared = AppleSignInManager()
    private init() {}

    let appleSignInQueue = DispatchQueue(label: "appleSignInQueue", attributes: .concurrent)
    let keychainManager = KeychainManager.shared
    let decoder = JSONDecoder()

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

    func generateAuthRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    func signInApple(
        authorization: ASAuthorization,
        completion: @escaping (Result<UserInitInfo, Error>) -> Void) {
        getRefreshToken()

        var fullName = ""

        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            if let userProvidedName = appleIDCredential.fullName {
                fullName = userProvidedName.formatted()
            }

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
                    let adjustedUser = UserInitInfo(
                        id: firUser.uid,
                        name: ((firUser.displayName ?? fullName)),
                        email: firUser.email ?? "",
                        thumbnail: nil)
                    completion(.success(adjustedUser))
                } else {
                    completion(.failure(AppleSignInError.failedToGetUserObject))
                }
            }
        }
    }

    func getRefreshToken() {
        if let authCode = keychainManager.getStringContent(
            by: UserDefaults.AppleSignInKey.authorizationCodeKey),
           let jwtToken = generateJWTToken(),
           let url = URL(string: """
               https://appleid.apple.com/auth/token?\
               client_id=\(AppleAuthConfig.bundleID.rawValue)&\
               client_secret=\(jwtToken)&\
               code=\(authCode)&\
               grant_type=authorization_code
               """) {

            var request = URLRequest(url: url)
            request.httpMethod = JHTTPMethod.post.rawValue
            request.setValue(JHTTPHeaderField.contentType.rawValue,
                             forHTTPHeaderField: JHTTPHeaderValue.xwwwFormURLEncoded.rawValue)
            URLSession.shared.dataTask(with: request) { [weak self] (data, response, err) in
                guard let self = self else { return }
                if let err = err {
                    print(err)
                    return
                }
                guard let response = response as? HTTPURLResponse,
                   response.statusCode == 200 else {
                    return
                }
                if let data = data {
                    do {
                        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let response = try self.decoder.decode(RefreshTokenResponse.self, from: data)
                        self.keychainManager.save(
                            stringContent: response.refreshToken,
                            by: UserDefaults.AppleSignInKey.refreshTokenKey)
                    } catch {
                        print(error)
                        return
                    }
                }
            }.resume()
        }
    }

    func revokeCredential(completion: @escaping (Result<String, Error>) -> Void) {
        if let refreshToken = keychainManager.getStringContent(
            by: UserDefaults.AppleSignInKey.refreshTokenKey),
           let jwtToken = generateJWTToken(),
           let url = URL(string: """
                         https://appleid.apple.com/auth/revoke?\
                         client_id=\(AppleAuthConfig.bundleID.rawValue)&\
                         client_secret=\(jwtToken)&\
                         token=\(refreshToken)&\
                         token_type_hint=refresh_token
                         """) {

            var request = URLRequest(url: url)
            request.httpMethod = JHTTPMethod.post.rawValue
            request.setValue(JHTTPHeaderField.contentType.rawValue,
                             forHTTPHeaderField: JHTTPHeaderValue.xwwwFormURLEncoded.rawValue)

            URLSession.shared.dataTask(with: request) { (_, response, err) in
                if let err = err {
                    completion(.failure(err))
                    return
                }
                guard let response = response as? HTTPURLResponse,
                      response.statusCode == 200 else {
                    completion(.failure(AppleSignInError.responseError))
                    return
                }
                completion(.success("Success"))
            }.resume()
        } else {
            completion(.failure(AppleSignInError.noValidJWT))
        }
    }

    func generateJWTToken() -> JWTToken? {
        struct MyClaims: Claims {
            let iss: String
            let iat: Date
            let exp: Date
            let aud: String
            let sub: String
        }

        let myHeader = Header(kid: AppleAuthConfig.p8KeyID.rawValue)
        let myClaims = MyClaims(iss: AppleAuthConfig.teamID.rawValue,
                                iat: Date(),
                                exp: Date(timeIntervalSinceNow: 3600),
                                aud: "https://appleid.apple.com",
                                sub: AppleAuthConfig.bundleID.rawValue)
        var myJWT = JWT(header: myHeader, claims: myClaims)

        if let filePath = Bundle.main.path(
            forResource: AppleAuthConfig.privateKeyFileName.rawValue,
            ofType: "p8") {
            do {
                let privateContent = try String(contentsOfFile: filePath)
                if let privateKey = privateContent.data(using: .utf8) {
                    let jwtSigner = JWTSigner.es256(privateKey: privateKey)
                    let signedJWT = try myJWT.sign(using: jwtSigner)
                    return signedJWT
                } else {
                    print("no valid private key")
                    return nil
                }
            } catch {
                print("decode failed")
                return nil
            }
        } else {
            print("file path is nil")
            return nil
        }
    }
}
