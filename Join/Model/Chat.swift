//
//  Message.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import Foundation

typealias ChatroomID = String

enum MessageType: CaseIterable, Codable {
    case text
}

enum ChatroomType {
    case friend
    case unknown

    var collectionName: String {
        switch self {
        case .friend: return "Friends"
        case .unknown: return "UnknownChat"
        }
    }
}

struct Chatroom {
    let id: ChatroomID
    let member: [UserID]
    var messages: [Message]

    var toInitDict: [String: Any] {
        return [
            "id": id as Any,
            "member": member as Any
        ]
    }
}

struct Message: Codable {
    let sender: UserID
    let type: MessageType
    let content: String
    let time: Date
}

struct UnknownChat: Codable {
    let id: UserID
    var chatroomID: ChatroomID
}
