//
//  UserDefaultsManager.swift
//  Join
//
//  Created by Riley Lai on 2022/11/16.
//

import Foundation

extension UserDefaults {
    enum AppleSignInKey {
        static let authorizationCodeKey = "authorizationCode"
        static let refreshTokenKey = "refreshToken"
    }

    enum UserKey {
        static let uidKey = "uid"
        static let userNameKey = "userName"
        static let userThumbnailURLKey = "userThumbnailURL"
        static let userInterestsKey = "userInterestsKey"
        static let userSkillsKey = "userSkillsKey"
    }
}
