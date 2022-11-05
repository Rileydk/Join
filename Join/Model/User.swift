//
//  User.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation

var myAccount = riley

let riley = User(
    id: "1qFVcUf1MZh90PDelqfU", name: "Riley Lai",
    email: "ddd@gmail.com",
    thumbnailURL: "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/DA32761A-2775-414C-95E8-F01DCB2CDD66?alt=media&token=c6ac5b7e-1e53-4d0b-813a-eb12c051bf6d"
)

let yichen = User(
    id: "6z63wggZ1FdOnBEA7Q6s", name: "Yi Chen",
    email: "ccc@gmail.com",
    thumbnailURL: "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/25E3357B-A23A-4852-884A-B424FB6ED3FC?alt=media&token=75cc10c7-534b-4e7f-a9fd-45ddcd73d76e"
)

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
    var interest = [String]()
    var skills = [String]()
    var posts = [String]()
    var friends = [UserID]()
    var sentRequests = [UserID]()
    var receivedRequests = [UserID]()
}
