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

    func setUserBasicInfo(user: JUser) {
        UserDefaults.standard.setValue(user.id, forKey: UserDefaults.UserKey.uidKey)
        UserDefaults.standard.setValue(user.thumbnailURL, forKey: UserDefaults.UserKey.userThumbnailURLKey)
        UserDefaults.standard.setValue(user.name, forKey: UserDefaults.UserKey.userNameKey)
        UserDefaults.standard.setValue(user.interests, forKey: UserDefaults.UserKey.userInterestsKey)
    }

    func clearUserInfo() {
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.uidKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userThumbnailURLKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userNameKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userInterestsKey)
    }
}
