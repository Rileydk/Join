//
//  ChatroomManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/8.
//

import Foundation

class ChatroomManager {
    static let shared = ChatroomManager()
    private init() {}
    let chatroomQueue = DispatchQueue(label: "chatroomQueue", attributes: .concurrent)
    var myID: UserID? {
        UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)
    }

    let firestoreManager = FirestoreManager.shared

    
}
