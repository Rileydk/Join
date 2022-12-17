//
//  FirebaseAuthManager.swift
//  Join
//
//  Created by Riley Lai on 2022/11/24.
//

import Foundation
import FirebaseAuth

extension FirebaseManager {
    func updateAuthentication(
        oldInfo: JUser, newInfo: JUser ,
        completion: @escaping (Result<String, Error>) -> Void) {
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            firebaseQueue.async { [weak self] in
                let group = DispatchGroup()
                if oldInfo.name != newInfo.name {
                    group.enter()
                    changeRequest?.displayName = newInfo.name
                    changeRequest?.commitChanges { err in
                        if let err = err {
                            group.leave()
                            group.notify(queue: .main) {
                                completion(.failure(err))
                            }
                            return
                        }
                        group.leave()
                    }
                }

                if oldInfo.email != newInfo.email {
                    group.enter()
                    self?.myAuth.currentUser?.updateEmail(to: newInfo.email) { err in
                        if let err = err {
                            group.leave()
                            group.notify(queue: .main) {
                                completion(.failure(err))
                            }
                            return
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    completion(.success("Success"))
                }
            }
        }
}
