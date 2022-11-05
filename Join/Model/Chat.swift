//
//  Message.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import Foundation

typealias ChatroomID = String

enum MessageType: CaseIterable {
    case text
}

struct Chatroom {
    let id: ChatroomID
    let member: [UserID]
    var messages: [Message]
}

struct Message {
    let sender: UserID
    let type: MessageType
    let content: String
    let time: Date
}
