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
    case unknown
    case friend
    case group

    var buttonTitle: String {
        switch self {
        case .unknown: return "陌生訊息"
        case .friend: return "好友訊息"
        case .group: return "群組訊息"
        }
    }

    var collectionName: String {
        switch self {
        case .unknown: return "UnknownChat"
        case .friend: return "Friends"
        case .group: return "GroupChatrooms"
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

struct GroupChatroom: Codable {
    var id: ChatroomID
    var name: String
    var imageURL: URLString
    var members: [UserID]
    var admin: UserID
    var messages: [Message]?

    var toInitDict: [String: Any] {
        return [
            "id": id as Any,
            "name": name as Any,
            "image": imageURL as Any,
            "members": members as Any
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
    let chatroomID: ChatroomID
}
