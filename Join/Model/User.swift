//
//  User.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation

var myAccount = riley

enum Relationship: CaseIterable {
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
        }
    }
}

typealias UserID = String

struct User: Codable, Hashable {
    let id: UserID
    var name: String
    var email: String
    var thumbnailURL: URLString
    var interests = [String]()
    var skills = [String]()
    var sentRequests = [UserID]()
    var receivedRequests = [UserID]()
}

struct Friend: Codable {
    let id: UserID
    var chatroomID: ChatroomID?
}
