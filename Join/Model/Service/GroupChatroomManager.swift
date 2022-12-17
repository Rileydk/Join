//
//  GroupChatroomManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/17.
//

import Foundation

extension FirebaseManager {
    func createGroupChatroom(
        groupChatroom: GroupChatroom, members: [ChatroomMember],
        completion: @escaping (Result<ChatroomID, Error>) -> Void) {
        let groupChatroomsRef = FirestoreEndpoint.groupChatroom.ref
        let chatroomID = groupChatroomsRef.document().documentID
        var groupChatroom = groupChatroom
        groupChatroom.id = chatroomID
        groupChatroom.createdTime = Date()

        firebaseQueue.async { [weak self] in
            let group = DispatchGroup()
            group.enter()
            groupChatroomsRef.document(chatroomID).setData(groupChatroom.toDict) { err in
                if let err = err {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                    return
                }
                group.leave()
            }

            group.wait()
            group.enter()
            self?.addNewGroupChatMembers(chatroomID: chatroomID, selectedMembers: members) { result in
                switch result {
                case .success:
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                }
            }

            group.notify(queue: .main) {
                completion(.success(chatroomID))
            }
        }
    }

    func addNewGroupChatMembers(
        chatroomID: ChatroomID, selectedMembers: [ChatroomMember],
        completion: @escaping (Result<String, Error>) -> Void) {
        firebaseQueue.async { [weak self] in
            var newMembers = [ChatroomMember]()
            var exitedMembers = [ChatroomMember]()

            let group = DispatchGroup()
            group.enter()
            self?.getAllGroupChatMembersIncludingExit(chatroomID: chatroomID) { result in
                switch result {
                case .success(let allMembers):
                    for member in allMembers {
                        for selectedMember in selectedMembers {
                            if member.userID == selectedMember.userID {
                                exitedMembers.append(selectedMember)
                            } else {
                                newMembers.append(selectedMember)
                            }
                        }
                    }
                    group.leave()

                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                }
            }

            group.wait()
            if newMembers.isEmpty && exitedMembers.isEmpty {
                newMembers = selectedMembers
            }

            if !exitedMembers.isEmpty {
                group.enter()
                let exitedMembersIDs = exitedMembers.map { $0.userID }
                self?.updateGroupChatroomMemberStatus(
                    setTo: .join, membersIDs: exitedMembersIDs,
                    chatroomID: chatroomID, completion: { result in
                    switch result {
                    case .success:
                        group.leave()
                    case .failure(let err):
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                    }
                })
            }

            if !newMembers.isEmpty {
                newMembers.forEach {
                    group.enter()
                    let ref = FirestoreEndpoint.groupChatroom.ref.document(chatroomID).collection("Members")
                    ref.document($0.userID).setData($0.toDict) { err in
                        if let err = err {
                            group.leave()
                            group.notify(queue: .main) {
                                completion(.failure(err))
                            }
                            return
                        }
                        group.leave()
                    }
                }
            }

            group.wait()
            selectedMembers.forEach {
                group.enter()
                let ref = FirestoreEndpoint.users.ref
                ref.document($0.userID)
                    .collection("GroupChats").document(chatroomID)
                    .setData(["chatroomID": chatroomID]) { err in
                    if let err = err {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                        return
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(.success("Success"))
            }
        }
    }

    func getAllGroupChatMembersIncludingExit(
        chatroomID: ChatroomID,
        completion: @escaping (Result<[ChatroomMember], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        ref.document(chatroomID).collection("Members").getDocuments { (snapshot, err) in
            if let err = err {
                print("error")
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let members: [ChatroomMember] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: ChatroomMember.self)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                completion(.success(members))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getAllCurrentGroupChatMembers(
        chatroomID: ChatroomID,
        completion: @escaping (Result<[UserID], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        ref.document(chatroomID).collection("Members").whereField("currentMemberStatus", isEqualTo: "join").getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let membersIDs: [UserID] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: ChatroomMember.self).userID
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                completion(.success(membersIDs))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getGroupChatroomInfo(
        chatroomID: ChatroomID,
        completion: @escaping (Result<GroupChatroom, Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        ref.document(chatroomID).getDocument { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                do {
                    let chatroomInfo = try snapshot.data(as: GroupChatroom.self)
                    completion(.success(chatroomInfo))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func addNewGroupMessage(
        message: Message, chatroomID: ChatroomID,
        completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreEndpoint.groupMessages(chatroomID).ref
        let documentID = ref.document().documentID
        var message = message
        message.messageID = documentID

        ref.document(documentID).setData(message.toDict) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success("Success"))
        }
    }

    func listenToNewGroupMessages(
        chatroomID: ChatroomID,
        completion: @escaping (Result<[Message], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupMessages(chatroomID).ref
        newMessageListener = ref.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let querySnapshot = querySnapshot {
                let messages: [Message] = querySnapshot.documentChanges.compactMap {
                    do {
                        return try $0.document.data(as: Message.self)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                if !querySnapshot.metadata.hasPendingWrites {
                    completion(.success(messages))
                }

            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getAllSavedGroupChatroomIDs(completion: @escaping (Result<[ChatroomID], Error>) -> Void) {
        let ref = FirestoreMyDocEndpoint.myGroupChat.ref
        ref.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let savedGroupChats: [SavedGroupChat] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: SavedGroupChat.self)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                let chatroomIDs = savedGroupChats.map { $0.chatroomID }
                completion(.success(chatroomIDs))

            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }

    }

    func getAllMessagesCombinedWithEachGroup(
        messagesItems: [GroupMessageListItem],
        completion: @escaping (Result<[GroupMessageListItem], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        let chatroomIDs = messagesItems.map { $0.chatroomID }
        var messagesItems = messagesItems

        firebaseQueue.async {
            let group = DispatchGroup()
            for chatroomID in chatroomIDs {
                group.enter()
                ref.document(chatroomID).collection("Messages")
                    .order(by: "time", descending: true)
                    .getDocuments { (snapshot, err) in
                    if let err = err {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                    }
                    if let snapshot = snapshot {
                        let messages: [Message] = snapshot.documents.compactMap {
                            do {
                                return try $0.data(as: Message.self)
                            } catch {
                                group.leave()
                                group.notify(queue: .main) {
                                    completion(.failure(error))
                                }
                                return nil
                            }
                        }

                        for index in 0 ..< messagesItems.count
                        where messagesItems[index].chatroomID == chatroomID {
                            messagesItems[index].messages = messages
                        }

                        group.leave()

                    } else {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(CommonError.noValidQuerysnapshot))
                        }
                    }
                }
            }
            group.notify(queue: .main) {
                completion(.success(messagesItems))
            }
        }
    }

    func getAllGroupMessages(
        completion: @escaping (Result<[GroupMessageListItem], Error>) -> Void) {
        var shouldContinue = true
        var chatroomIDsBox = [ChatroomID]()
        var groupMessageListItems = [GroupMessageListItem]()

        firebaseQueue.async { [weak self] in
            let group = DispatchGroup()
            group.enter()
            self?.getAllSavedGroupChatroomIDs { result in
                switch result {
                case .success(let chatroomIDs):
                    chatroomIDsBox = chatroomIDs
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        print(err)
                    }
                }
            }

            group.wait()
            if chatroomIDsBox.isEmpty {
                shouldContinue = false
                group.notify(queue: .main) {
                    completion(.failure(CommonError.noMessage))
                }
            }
            guard shouldContinue else { return }
            group.enter()
            self?.getAllGroupChatroomInfo(chatroomIDs: chatroomIDsBox) { result in
                switch result {
                case .success(let groupListItems):
                    groupMessageListItems = groupListItems
                    group.leave()
                case .failure(let err):
                    if err as? CommonError == CommonError.noExistChatroom {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                    } else {
                        shouldContinue = false
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                    }
                }
            }

            group.wait()
            guard shouldContinue else { return }
            group.enter()
            // swiftlint:disable line_length
            self?.getAllMessagesCombinedWithEachGroup(messagesItems: groupMessageListItems) { result in
                switch result {
                case .success(let groupListItems):
                    groupMessageListItems = groupListItems
                    group.leave()
                case .failure(let err):
                    if err as? CommonError == CommonError.noMessage {
                        print("No message")
                        group.leave()
                    } else {
                        shouldContinue = false
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                    }
                }
            }

            group.wait()
            guard shouldContinue else { return }
            group.enter()
            self?.getMyLastTimeInGroupChatroom(type: .group, messagesItems: groupMessageListItems) { result in
                switch result {
                case .success(let messagesItems):
                    group.leave()
                    group.notify(queue: .main) {
                        groupMessageListItems = groupMessageListItems.sorted(by: {
                            $0.messages.first?.time ?? $0.chatroom.createdTime > $1.messages.first?.time ?? $0.chatroom.createdTime
                        })
                        completion(.success(messagesItems))
                    }
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                }
            }
        }
    }

    func getAllGroupChatroomInfo(chatroomIDs: [ChatroomID], completion: @escaping (Result<[GroupMessageListItem], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        var groupMessageListItem = [GroupMessageListItem]()

        guard !chatroomIDs.isEmpty else {
            completion(.failure(CommonError.noExistChatroom))
            return
        }

        ref.whereField("id", in: chatroomIDs).getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                snapshot.documents.forEach {
                    do {
                        let chatroom = try $0.data(as: GroupChatroom.self)
                        groupMessageListItem.append(GroupMessageListItem(chatroomID: chatroom.id, chatroom: chatroom, lastTimeInChatroom: Date()))
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(groupMessageListItem))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getGroupMessages(of chatroomID: ChatroomID, completion: @escaping (Result<[Message], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        ref.document(chatroomID).collection("Messages").order(by: "time").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let querySnapshot = querySnapshot {
                let messages: [Message] = querySnapshot.documents.compactMap {
                    do {
                        return try $0.data(as: Message.self)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                completion(.success(messages))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func updateGroupChatroomMemberStatus(setTo status: MemberStatus, membersIDs: [UserID], chatroomID: ChatroomID, completion: @escaping (Result<String, Error>) -> Void) {
        // 變更 chatroom 中成員狀態
        // 從成員下移除 chatroomID
        firebaseQueue.async {
            let membersRef = FirestoreEndpoint.groupMembers(chatroomID).ref

            let group = DispatchGroup()
            membersIDs.forEach {
                group.enter()
                membersRef.document($0).updateData(["currentMemberStatus": status.rawValue]) { err in
                    if let err = err {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                        return
                    }
                    group.leave()
                }
            }

            group.wait()
            membersIDs.forEach {
                group.enter()
                let userGroupchatRef = FirestoreEndpoint.otherGroupChat($0).ref
                userGroupchatRef.document(chatroomID).delete { err in
                    if let err = err {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                        return
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(.success("Successfully remove members"))
            }
        }
    }

    func updateGroupChatroomInoutStatus(setTo status: InoutStatus, chatroomID: ChatroomID, completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let membersRef = FirestoreEndpoint.groupMembers(chatroomID).ref
        firebaseQueue.async {
            let group = DispatchGroup()
            group.enter()
            membersRef.document(myID).updateData(["currentInoutStatus": status.rawValue]) { err in
                if let err = err {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                    return
                }
                group.leave()
            }

            if status == .out {
                group.enter()
                membersRef.document(myID).updateData(["lastTimeInChatroom": Date()]) { err in
                    if let err = err {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                        return
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                completion(.success(status.rawValue))
            }
        }
    }

    func getMyLastTimeInGroupChatroom(type: ChatroomType, messagesItems: [GroupMessageListItem], completion: @escaping (Result<[GroupMessageListItem], Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        var messagesItems = messagesItems
        let group = DispatchGroup()
        for item in messagesItems {
            group.enter()
            let ref = FirestoreEndpoint.groupMembers(item.chatroomID).ref
            ref.document(myID).getDocument { (snapshot, err) in
                if let err = err {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                    return
                }
                if let snapshot = snapshot {
                    do {
                        let myMemberInfo = try snapshot.data(as: ChatroomMember.self)
                        for index in 0 ..< messagesItems.count where messagesItems[index].chatroomID == item.chatroomID {
                            messagesItems[index].lastTimeInChatroom = myMemberInfo.lastTimeInChatroom
                        }
                        group.leave()
                    } catch {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(error))
                        }
                        return
                    }
                } else {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(CommonError.noValidQuerysnapshot))
                    }
                    return
                }
            }
        }
        group.notify(queue: .main) {
            completion(.success(messagesItems))
        }
    }
}
