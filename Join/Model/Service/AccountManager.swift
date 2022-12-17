//
//  AccountManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/17.
//

import Foundation

extension FirebaseManager {
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    func clearUserData(completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = myID else { return }
        let myRef = FirestoreEndpoint.users.ref.document(myID)
        let group = DispatchGroup()

        var errorMessage: Error?

        firebaseQueue.async { [weak self] in
            guard let self = self else { return }

            // Delete all my projects and records under user
            group.enter()
            self.getAllMyProjectsItems(testID: myID) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let projectIDs):
                    let projectRef = FirestoreEndpoint.projects.ref
                    let deleteProjectsUnderUserGroup = DispatchGroup()
                    projectIDs.forEach {
                        deleteProjectsUnderUserGroup.enter()
                        self.deleteDocument(ref: projectRef.document($0.projectID)) {
                            deleteProjectsUnderUserGroup.leave()
                        }
                    }
                    let myProjectRef = FirestoreMyDocEndpoint.myPosts.ref
                    projectIDs.forEach {
                        deleteProjectsUnderUserGroup.enter()
                        self.deleteDocument(ref: myProjectRef.document($0.projectID)) {
                            deleteProjectsUnderUserGroup.leave()
                        }
                    }
                    deleteProjectsUnderUserGroup.notify(queue: self.firebaseQueue) {
                        group.leave()
                    }
                case .failure(let err):
                    errorMessage = err
                    group.leave()
                }
            }

            // myWorks
            // 刪除 user 下的 records 和 works
            group.wait()
            group.enter()
            self.getUserWorks(userID: myID) { result in
                switch result {
                case .success(let works):
                    guard !works.isEmpty else {
                        group.leave()
                        return
                    }
                    let deleteWorksGroup = DispatchGroup()
                    for work in works {
                        deleteWorksGroup.enter()
                        self.getWorkRecords(userID: myID, by: work.workID) { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success(let records):

                                self.firebaseQueue.async {
                                    let workRef = FirestoreEndpoint.users.ref
                                        .document(myID).collection("Works")
                                    let workRecordRef = workRef.document(work.workID).collection("Records")

                                    let deleteWorkAndRecordsGroup = DispatchGroup()
                                    records.forEach {
                                        deleteWorkAndRecordsGroup.enter()
                                        self.deleteDocument(ref: workRecordRef.document($0.recordID)) {
                                            deleteWorkAndRecordsGroup.leave()
                                        }
                                    }
                                    deleteWorkAndRecordsGroup.wait()
                                    deleteWorkAndRecordsGroup.enter()
                                    self.deleteDocument(ref: workRef.document(work.workID) ) {
                                        deleteWorkAndRecordsGroup.leave()
                                    }
                                    deleteWorkAndRecordsGroup.notify(queue: self.firebaseQueue) {
                                        deleteWorksGroup.leave()
                                    }
                                }
                            case .failure(let err):
                                errorMessage = err
                                deleteWorksGroup.leave()
                            }
                        }
                    }
                    deleteWorksGroup.notify(queue: self.firebaseQueue) {
                        group.leave()
                    }
                case .failure(let err):
                    errorMessage = err
                    group.leave()
                }
            }

            // myFriends
            // 刪除 user 下全部好友、從好友的好友中刪除自己；刪除 user 下好友聊天室、刪除這些好友聊天室及從屬的訊息
            group.wait()
            group.enter()
            self.getAllFriendsAndChatroomsInfo(type: .friend) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let friendsAndChatrooms):
                    guard !friendsAndChatrooms.isEmpty else {
                        group.leave()
                        return
                    }

                    let friendsIDs = friendsAndChatrooms.map { $0.id }
                    let userRef = FirestoreEndpoint.users.ref
                    let deleteFriendsGroup = DispatchGroup()

                    self.firebaseQueue.async {
                        // 刪除自己帳號下的好友
                        let myFriendsRef = FirestoreMyDocEndpoint.myFriends.ref
                        friendsIDs.forEach {
                            deleteFriendsGroup.enter()
                            self.deleteDocument(ref: myFriendsRef.document($0)) {
                                deleteFriendsGroup.leave()
                            }
                        }
                        // 刪除對方 user / Friends 紀錄下的自己及共同聊天室
                        friendsIDs.forEach {
                            deleteFriendsGroup.enter()
                            self.deleteDocument(ref: userRef.document($0)
                                .collection("Friends").document(myID)) {
                                deleteFriendsGroup.leave()
                            }
                        }

                        // 刪聊天室
                        let chatroomsIDs = friendsAndChatrooms.map { $0.chatroomID }
                        for chatroomID in chatroomsIDs {
                            deleteFriendsGroup.enter()
                            guard let chatroomID = chatroomID else {
                                deleteFriendsGroup.leave()
                                break
                            }
                            self.deleteChatroom(chatroomID: chatroomID) {
                                deleteFriendsGroup.leave()
                            }
                        }
                        deleteFriendsGroup.notify(queue: self.firebaseQueue) {
                            group.leave()
                        }
                    }

                case .failure(let err):
                    errorMessage = err
                    group.leave()
                }
            }

            // UnknownChat
            // 刪除所有陌生訊息、對方儲存的紀錄、聊天室紀錄
            group.wait()
            group.enter()
            self.getAllFriendsAndChatroomsInfo(type: .unknown) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let unknownsAndChatrooms):
                    guard !unknownsAndChatrooms.isEmpty else {
                        group.leave()
                        return
                    }

                    let unknownsIDs = unknownsAndChatrooms.map { $0.id }
                    // 刪除自己帳號下的陌生訊息
                    let myUnknownsRef = FirestoreEndpoint.users.ref.document(myID).collection("UnknownChat")
                    let deleteUnknownGroup = DispatchGroup()

                    unknownsIDs.forEach {
                        deleteUnknownGroup.enter()
                        self.deleteDocument(ref: myUnknownsRef.document($0)) {
                            deleteUnknownGroup.leave()
                        }
                    }
                    // 刪除對方 user / UnknownChat 紀錄下的自己及共同聊天室
                    let userRef = FirestoreEndpoint.users.ref
                    unknownsIDs.forEach {
                        deleteUnknownGroup.enter()
                        self.deleteDocument(ref: userRef.document($0)
                            .collection("UnknownChat").document(myID)) {
                            deleteUnknownGroup.leave()
                        }
                    }
                    // 刪除聊天室
                    let chatroomsIDs = unknownsAndChatrooms.map { $0.chatroomID }
                    for chatroomID in chatroomsIDs {
                        deleteUnknownGroup.enter()
                        guard let chatroomID = chatroomID else {
                            deleteUnknownGroup.leave()
                            break
                        }
                        self.deleteChatroom(chatroomID: chatroomID) {
                            deleteUnknownGroup.leave()
                        }
                    }
                    deleteUnknownGroup.notify(queue: self.firebaseQueue) {
                        group.leave()
                    }
                case .failure(let err):
                    errorMessage = err
                    group.leave()
                }
            }

            // myGroupchats
            // 刪除 user 下的 groupchats、修改成員
            group.wait()
            group.enter()
            self.getAllGroupMessages { result in
                switch result {
                case .success(let groupMessageList):
                    guard !groupMessageList.isEmpty else {
                        group.leave()
                        return
                    }

                    let groupChatroomIDs = groupMessageList.map { $0.chatroomID }
                    let groupDeleteGroup = DispatchGroup()
                    for chatroomID in groupChatroomIDs {
                        groupDeleteGroup.enter()
                        let myGroupRef = FirestoreMyDocEndpoint.myGroupChat.ref
                        self.deleteDocument(ref: myGroupRef.document(chatroomID)) {
                            groupDeleteGroup.leave()
                        }

                        groupDeleteGroup.enter()
                        let groupChatMembersRef = FirestoreEndpoint.groupMembers(chatroomID).ref
                        self.deleteDocument(ref: groupChatMembersRef.document(myID)) {
                            groupDeleteGroup.leave()
                        }

                    }
                    groupDeleteGroup.notify(queue: self.firebaseQueue) {
                        group.leave()
                    }
                case .failure(let err):
                    errorMessage = err
                    group.leave()
                }
            }

            // Delete user data
            group.wait()
            group.enter()
            self.deleteDocument(ref: myRef) {
                group.leave()
            }

            group.notify(queue: .main) {
                if let error = errorMessage {
                    completion(.failure(error))
                } else {
                    completion(.success("Success"))
                }
            }
        }
    }
}
