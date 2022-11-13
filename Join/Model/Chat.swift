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
typealias MemberID = String

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

enum MemberStatus: String, Codable {
    case join
    case exit
}

enum InoutStatus: String, Codable {
    case `in`
    case out
}

struct Chatroom: Codable {
    let id: ChatroomID

    var toDict: [String: Any] {
        return [
            "id": id as Any
        ]
    }
}

struct GroupChatroom: Codable {
    var id: ChatroomID
    var name: String
    var imageURL: URLString
    var admin: UserID
    var createdTime: Date

    var toDict: [String: Any] {
        return [
            "id": id as Any,
            "name": name as Any,
            "imageURL": imageURL as Any,
            "admin": admin as Any,
            "createdTime": createdTime as Any
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

struct ChatroomMember: Codable {
    let userID: UserID
    var currentMemberStatus: MemberStatus
    var currentInoutStatus: InoutStatus
    var lastTimeInChatroom: Date

    var toDict: [String: Any] {
        return [
            "userID": userID as Any,
            "currentMemberStatus": currentMemberStatus.rawValue as Any,
            "currentInoutStatus": currentInoutStatus.rawValue as Any,
            "lastTimeInChatroom": lastTimeInChatroom as Any
        ]
    }
}

struct SavedChat: Codable {
    let id: UserID
    var chatroomID: ChatroomID
}

struct MessageListItem: Codable {
    let chatroomID: ChatroomID
    let objectID: UserID
    var messages = [Message]()
}

struct SavedGroupChat: Codable {
    var chatroomID: ChatroomID
}

struct GroupMessageListItem {
    let chatroomID: ChatroomID
    let chatroom: GroupChatroom
    var messages = [Message]()
}

struct WholeInfoMessage {
    let sender: User
    let message: Message
}
