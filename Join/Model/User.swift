//
//  User.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation

let myAccount = User(
    id: "me", name: "Riley Lai",
    email: "ddd@gmail.com",
    thumbnailURL: "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/5F193315-633D-48D3-A10D-0BC271F326D8?alt=media&token=04f47c5e-825f-4019-8995-305b528308ed",
    interest: nil,
    skills: nil,
    posts: nil,
    friends: nil
)

struct User {
    let id: String
    let name: String
    let email: String
    let thumbnailURL: URLString
    let interest: [String]?
    let skills: [String]?
    let posts: [String]?
    let friends: [String]?
}

struct UserId: Hashable, Codable {
    let id: String

    var toDict: [String: Any] {
        return [
            "id": id as Any
        ]
    }
}

struct Friend {
    let id: String
}
