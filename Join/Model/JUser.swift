//
//  User.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation
import FirebaseAuth

enum Relationship: CaseIterable {
    case mySelf
    case friend
    case sentRequest
    case receivedRequest
    case unknown

    var title: String {
        switch self {
        case .friend: return "好友"
        case .sentRequest: return "已送出邀請"
        case .receivedRequest: return "接受邀請"
        case .unknown: return "加為好友"
        default: return ""
        }
    }
}

typealias UserID = String

struct JUser: Codable, Hashable {
    let id: UserID
    var name: String
    var email: String
    var thumbnailURL: URLString?
    var introduction: String?
    var interests = [String]()
    var skills = [String]()
    var sentRequests = [UserID]()
    var receivedRequests = [UserID]()

    var toDict: [String: Any] {
        return [
            "id": id as Any,
            "name": name as Any,
            "email": email as Any,
            "thumbnailURL": thumbnailURL as Any,
            "introduction": introduction as Any,
            "interests": interests as Any,
            "skills": skills as Any,
            "sentRequests": sentRequests as Any,
            "receivedRequests": receivedRequests as Any
        ]
    }
}

struct Friend: Codable {
    let id: UserID
    var chatroomID: ChatroomID?
}
