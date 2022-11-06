//
//  Message.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import Foundation
import UIKit

typealias ChatroomID = String
typealias MessageID = String

enum MessageType: String, CaseIterable, Codable {
    case text
}

enum ChatroomType: CaseIterable {
    case friend
    case unknown

    var buttonTitle: String {
        switch self {
        case .friend: return "好友訊息"
        case .unknown: return "陌生訊息"
        }
    }

    var collectionName: String {
        switch self {
        case .friend: return "Friends"
        case .unknown: return "UnknownChat"
        }
    }
}

struct Chatroom: Codable {
    let id: ChatroomID
    let member: [UserID]
    var messages: [Message]?

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

struct SavedChat: Codable {
    let id: UserID
    var chatroomID: ChatroomID
}

struct MessageListItem: Codable {
    let userID: UserID
    let latestMessage: Message
}
