//
//  User.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation

let myAccount = User(
    id: "1qFVcUf1MZh90PDelqfU", name: "Riley Lai",
    email: "ddd@gmail.com",
    thumbnailURL: "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/DA32761A-2775-414C-95E8-F01DCB2CDD66?alt=media&token=c6ac5b7e-1e53-4d0b-813a-eb12c051bf6d",
    interest: nil,
    skills: nil,
    posts: nil,
    friends: nil
)

struct User: Codable, Hashable {
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
