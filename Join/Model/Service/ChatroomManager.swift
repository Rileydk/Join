//
//  ChatroomManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/8.
//

import Foundation

extension FirebaseManager {
    func getChatroom(id: UserID,
                     completion: @escaping (Result<ChatroomID, Error>) -> Void) {
        // 是否是朋友
        checkIsFriend(id: id) { [unowned self] result in
            switch result {
                // 若是朋友，確認是否有既存的 chatroom
            case .success(let friend):
                if let chatroomID = friend.chatroomID {
                    completion(.success(chatroomID))
                    return
                } else {
                    // 若沒有既存的 chatroom，開一個新的
                    self.createChatroom(id: id, type: .friend) { result in
                        switch result {
                        case .success(let chatroomID):
                            completion(.success(chatroomID))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                // 若不是朋友，確認過去是否有陌生訊息
                if error as? CommonError == CommonError.notFriendYet {
                    self.checkUnknownChatroom(id: id) { [unowned self] result in
                        switch result {
                        case .success(let chatroomID):
                            completion(.success(chatroomID))
                        case .failure(let error):
                            if error as? CommonError == CommonError.noExistChatroom {
                                self.createChatroom(id: id, type: .unknown) { result in
                                    switch result {
                                    case .success(let chatroomID):
                                        completion(.success(chatroomID))
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                }
                            } else {
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    completion(.failure(error))
                    return
                }
            }
        }
    }

    func checkUnknownChatroom(id: UserID, completion: @escaping (Result<ChatroomID, Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let myDocRef = FirestoreEndpoint.users.ref.document(myID)
        myDocRef.collection("UnknownChat").document(id).getDocument { (documentSnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let snapshot = documentSnapshot {
                do {
                    let document = try snapshot.data(as: SavedChat.self)
                    guard let chatroomID = document.chatroomID else {
                        completion(.failure(CommonError.noExistChatroom))
                        return
                    }
                    completion(.success(chatroomID))
                } catch {
                    completion(.failure(CommonError.noExistChatroom))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
                return
            }
        }
    }

    func createChatroom(
        id: UserID, type: ChatroomType,
        completion: @escaping (Result<ChatroomID, Error>) -> Void) {
        firebaseQueue.async { [weak self] in
            let chatroomRef = FirestoreEndpoint.chatrooms.ref
            let chatroomID = chatroomRef.document().documentID
            let chatroom = Chatroom(id: chatroomID)

            let group = DispatchGroup()
            group.enter()
            chatroomRef.document(chatroomID).setData(chatroom.toDict) { error in
                if let error = error {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(error))
                    }
                    return
                }
                group.leave()
            }

            group.wait()
            guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
                fatalError("Doesn't have user id")
            }
            let membersRef = FirestoreEndpoint.privateChatroomMembers(chatroomID).ref
            [myID, id].forEach {
                group.enter()
                let member = ChatroomMember(
                    userID: $0, currentMemberStatus: .join,
                    currentInoutStatus: .out, lastTimeInChatroom: Date())
                membersRef.document($0).setData(member.toDict) { err in
                    if let err = err {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                    }
                    group.leave()
                }
            }

            group.wait()
            group.notify(queue: .main) { [weak self] in
                self?.saveChatroomID(to: type, id: id, chatroomID: chatroomID, completion: { result in
                    switch result {
                    case .success:
                        completion(.success(chatroomID))
                    case .failure(let err):
                        completion(.failure(err))
                    }
                })

            }
        }
    }

    func saveChatroomID(
        to type: ChatroomType, id: UserID, chatroomID: ChatroomID,
        completion: @escaping (Result<String, Error>) -> Void ) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let myDocRef = FirestoreEndpoint.users.ref.document(myID)
        let friendDocRef = FirestoreEndpoint.users.ref.document(id)
        let collectionName = type.collectionName

        let group = DispatchGroup()
        group.enter()
        myDocRef.collection(collectionName).document(id)
            .setData(["id": id, "chatroomID": chatroomID]) { error in
                if let error = error {
                    completion(.failure(error))
                    group.leave()
                    return
                }
                group.leave()
            }
        group.enter()
        friendDocRef.collection(collectionName).document(myID)
            .setData(["id": myID, "chatroomID": chatroomID]) { error in
                if let error = error {
                    completion(.failure(error))
                    group.leave()
                    return
                }
                group.leave()
            }
        group.notify(queue: .main) {
            completion(.success("Success"))
        }
    }

    func removeUnknownChat(of friend: UserID) {
        let ref = FirestoreEndpoint.users.ref
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let myUnknownChatDocRef = ref.document(myID)
            .collection(ChatroomType.unknown.collectionName).document(friend)
        let friendUnknownChatDocRef = ref.document(friend)
            .collection(ChatroomType.unknown.collectionName).document(myID)
        myUnknownChatDocRef.delete { error in
            if let error = error {
                print(error)
            }
        }
        friendUnknownChatDocRef.delete { error in
            if let error = error {
                print(error)
            }
        }
    }

    func getMessages(of chatroomID: ChatroomID, completion: @escaping (Result<[Message], Error>) -> Void) {
        let ref = FirestoreEndpoint.chatrooms.ref
        ref.document(chatroomID).collection("Messages")
            .order(by: "time").getDocuments { (querySnapshot, error) in
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

    func addNewMessage(
        message: Message, chatroomID: ChatroomID,
        completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreEndpoint.chatrooms.ref.document(chatroomID).collection("Messages")
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

    func listenToNewMessages(
        chatroomID: ChatroomID,
        completion: @escaping (Result<[Message], Error>) -> Void) {
        let ref = FirestoreEndpoint.messages(chatroomID).ref
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

    func detachNewMessageListener() {
        newMessageListener?.remove()
    }

    func getAllFriendsAndChatroomsInfo(
        type: ChatroomType,
        completion: @escaping (Result<[SavedChat], Error>) -> Void) {
        guard let myID = myID else {
            fatalError("Doesn't have user id")
        }
        let ref = FirestoreEndpoint.users.ref.document(myID).collection(type.collectionName)
        ref.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let snapshot = snapshot {
                // 過濾尚未建立 chatroom 者
                let chatroomsInfo: [SavedChat] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: SavedChat.self)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                completion(.success(chatroomsInfo))

            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getAllMatchedChatroomMessages(
        messagesList: [MessageListItem],
        completion: @escaping (Result<[MessageListItem], Error>) -> Void) {
        let chatrooms = messagesList.map { $0.chatroomID }
        var messagesList = messagesList

        firebaseQueue.async {
            let group = DispatchGroup()
            for index in 0 ..< chatrooms.count {
                group.enter()
                let ref = FirestoreEndpoint.messages(chatrooms[index]).ref
                ref.order(by: "time", descending: true).getDocuments { (snapshot, error) in
                    if let error = error {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(error))
                        }
                        return
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

                        for item in messagesList where item.chatroomID == messagesList[index].chatroomID {
                            messagesList[index].messages = messages
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
                messagesList = messagesList.filter { !$0.messages.isEmpty }
                completion(.success(messagesList))
            }
        }
    }

    func getAllMessagesCombinedWithSender(
        type: ChatroomType,
        completion: @escaping (Result<[MessageListItem], Error>) -> Void) {
        var shouldContinue = true
        var messagesList = [MessageListItem]()

        firebaseQueue.async { [weak self] in
            let group = DispatchGroup()
            group.enter()
            self?.getAllFriendsAndChatroomsInfo(type: type) { result in
                switch result {
                    // 取得所有存放在 user 下符合類別的 chatroom
                case .success(let savedChat):
                    messagesList = savedChat.map {
                        MessageListItem(
                            chatroomID: $0.chatroomID ?? "",
                            objectID: $0.id, lastTimeInChatroom: Date()
                        )
                    }.filter { !$0.chatroomID.isEmpty }
                    group.leave()
                case .failure(let error):
                    shouldContinue = false
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(error))
                    }
                }
            }

            group.wait()
            if messagesList.isEmpty {
                shouldContinue = false
                group.notify(queue: .main) {
                    completion(.failure(CommonError.noMessage))
                }
            }
            guard shouldContinue else { return }
            group.enter()
            self?.getAllMatchedChatroomMessages(messagesList: messagesList) { result in
                switch result {
                case .success(let fetchedMessagesList):
                    messagesList = fetchedMessagesList
                    group.leave()
                case .failure(let error):
                    shouldContinue = false
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(error))
                    }
                }
            }

            group.wait()
            guard shouldContinue else { return }
            group.enter()
            self?.getMyLastTimeInChatroom(messagesItems: messagesList, completion: { result in
                switch result {
                case .success(let messagesList):
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.success(messagesList))
                    }
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                }
            })
        }
    }

    func updatePrivateChatInoutStatus(
        setTo status: InoutStatus, chatroomID: ChatroomID,
        completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let membersRef = FirestoreEndpoint.privateChatroomMembers(chatroomID).ref
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

    func getPrivateChatroomMembers(
        chatroomID: ChatroomID,
        completion: @escaping (Result<[ChatroomMember], Error>) -> Void) {
        let membersRef = FirestoreEndpoint.privateChatroomMembers(chatroomID).ref
        membersRef.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
            }
            if let snapshot = snapshot {
                let members: [ChatroomMember] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: ChatroomMember.self)
                    } catch {
                        return nil
                    }
                }
                completion(.success(members))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getMyLastTimeInChatroom(
        messagesItems: [MessageListItem],
        completion: @escaping (Result<[MessageListItem], Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        var messagesItems = messagesItems
        let group = DispatchGroup()
        for item in messagesItems {
            group.enter()
            let ref = FirestoreEndpoint.privateChatroomMembers(item.chatroomID).ref
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
                        for index in 0 ..< messagesItems.count
                        where messagesItems[index].chatroomID == item.chatroomID {
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
