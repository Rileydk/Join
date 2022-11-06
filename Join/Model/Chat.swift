//
//  Message.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import Foundation

typealias ChatroomID = String
typealias MessageID = String

enum MessageType: String, CaseIterable, Codable {
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
    var messageID: MessageID
    let sender: UserID
    let type: MessageType
    let content: String
    let time: Date

    var toDict: [String: Any] {
        return [
            "messageID": messageID as Any,
            "sender": sender as Any,
            "type": type.rawValue as Any,
            "content": content as Any,
            "time": time as Any
        ]
    }
}

struct UnknownChat: Codable {
    let id: UserID
    var chatroomID: ChatroomID
}
