//
//  KeychainManager.swift
//  Join
//
//  Created by Riley Lai on 2022/11/24.
//

import Foundation
import KeychainAccess

class KeychainManager {
    static let shared = KeychainManager()
    private let service: Keychain
    private init() {
        service = Keychain(service: Bundle.main.bundleIdentifier!)
    }

    func save(stringContent: String, by key: String) {
        let uuid = UUID().uuidString
        UserDefaults.standard.setValue(uuid, forKey: key)
        service[uuid] = stringContent
    }

    func getStringContent(by key: String) -> String? {
        if let key = UserDefaults.standard.string(forKey: key) {
            return service[key]
        } else {
            return nil
        }
    }

    func clear(key: String) {
        service[key] = nil
    }
}
