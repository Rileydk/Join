//
//  UserManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/8.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum UserFirestoreColEndpoint {
    case users
    case friends(UserID)
    case unknownChat(UserID)
    case groupChats(UserID)
    case works(UserID)
    case workRecords(UserID, WorkID)

    var ref: CollectionReference {
        // swiftlint:disable identifier_name
        let db = Firestore.firestore()
        let users = db.collection("Users")

        let friends = "Friends"
        let unknownChat = "UnknownChat"
        let groupChats = "GroupChats"
        let works = "Works"
        let workRecords = "Records"

        switch self {
        case .users: return users
        case .friends(let userID): return users.document(userID).collection(friends)
        case .unknownChat(let userID): return users.document(userID).collection(unknownChat)
        case .groupChats(let userID): return users.document(userID).collection(groupChats)
        case .works(let userID): return users.document(userID).collection(works)
        case .workRecords(let userID, let workID):
            return users.document(userID).collection(works).document(workID).collection(workRecords)
        }
    }
}

enum UserDocField {
    enum User {
        static let receivedRequests = "receivedRequests"
        static let sentRequests = "sentRequests"
    }

    enum FriendSub {
        static let id = "id"
    }
}

class UserManager {
    static let shared = UserManager()
    private init() {}
    let userQueue = DispatchQueue(label: "userQueue", attributes: .concurrent)
    let lock = NSLock()
    var myID: UserID? {
        UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)
    }

    let firestoreManager = FirestoreManager.shared

    // MARK: - Methods

    func getSingleUserData(userID: UserID, completion: @escaping (JUser?) -> Void) {
        let userRef = FirestoreEndpoint.users.ref.document(userID)
        firestoreManager.getDocument(userRef) { (user: JUser?) in
            completion(user)
        }
    }

    // MARK: - Specific Use

    func getRelationship(userID: UserID, completion: @escaping (Relationship?) -> Void) {
        guard let myID = myID else { return }

        var relationship: Relationship?
        let group = DispatchGroup()
        userQueue.async { [weak self] in
            guard let self = self else { return }
            group.enter()
            let query = UserFirestoreColEndpoint.friends(myID).ref.whereField("id", isEqualTo: userID)
            self.firestoreManager.getDocuments(query) { (friends: [Friend]) in
                // 如果是朋友
                if !friends.isEmpty {
                    relationship = .friend
                }
                group.leave()
            }

            group.wait()
            if relationship == nil {
                group.enter()
                let ref = UserFirestoreColEndpoint.users.ref.document(myID)
                self.firestoreManager.getDocument(ref) { (myData: JUser?) in
                    guard let myData = myData else { return }
                    if myData.receivedRequests.contains(userID) {
                        relationship = .receivedRequest
                    } else if myData.sentRequests.contains(userID) {
                        relationship = .sentRequest
                    } else {
                        relationship = .unknown
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(relationship)
            }
        }
    }

    func getPortfolio(userID: UserID, completion: @escaping ([WorkItem]) -> Void) {
        var workItems = [WorkItem]()
        let group = DispatchGroup()
        userQueue.async { [weak self] in
            guard let self = self else { return }

            group.enter()
            let query = UserFirestoreColEndpoint.works(userID).ref
            self.firestoreManager.getDocuments(query) { (works: [Work]) in
                workItems = works.map {
                    WorkItem(workID: $0.workID, name: $0.name,
                             latestUpdatedTime: $0.latestUpdatedTime, records: [])

                }
                group.leave()
            }

            group.wait()
            if !workItems.isEmpty {
                for index in 0 ..< workItems.count {
                    group.enter()
                    let query = UserFirestoreColEndpoint.workRecords(userID, workItems[index].workID).ref
                    self.firestoreManager.getDocuments(query) { (records: [WorkRecord]) in
                        workItems[index].records = records
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                completion(workItems)
            }
        }
    }

    func sendFriendRequest(to userID: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = myID else { return }
        var errors = [Error]()
        let group = DispatchGroup()

        // 在對方收到的邀請新增自己
        group.enter()
        let objectRef = UserFirestoreColEndpoint.users.ref.document(userID)
        objectRef.updateData([UserDocField.User.receivedRequests:
                                FieldValue.arrayUnion([myID])]) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.lock.with { errors.append(error) }
            }
            group.leave()
        }

        // 在自己送出的邀請新增對方
        group.enter()
        let myRef = UserFirestoreColEndpoint.users.ref.document(myID)
        myRef.updateData([UserDocField.User.sentRequests: FieldValue.arrayUnion([userID])]) { error in
            if let error = error {
                self.lock.with { errors.append(error) }
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success("Success"))
            } else {
                completion(.failure(errors.first!))
            }
        }
    }

    func acceptFriendRequest(from userID: UserID,
                             completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = myID else { return }
        var errors = [Error]()
        var unknownChat: SavedChat?

        userQueue.async { [weak self] in
            guard let self = self else { return }
            let group = DispatchGroup()

            // 取得陌生聊天室（可能為nil）
            group.enter()
            let ref = UserFirestoreColEndpoint.unknownChat(myID).ref.document(userID)
            self.firestoreManager.getDocument(ref) { (savedChat: SavedChat?) in
                unknownChat = savedChat
                group.leave()
            }

            group.wait()
            // 將對方加入自己的好友
            group.enter()
            let friend = SavedChat(id: userID, chatroomID: unknownChat?.chatroomID)
            self.addNewFriend(friend, toUser: myID) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    self.lock.with { errors.append(error) }
                default: break
                }

            }

            // 將自己加入對方的好友
            group.enter()
            let me = SavedChat(id: myID, chatroomID: unknownChat?.chatroomID)
            self.addNewFriend(me, toUser: userID) { result in
                switch result {
                case .failure(let error):
                    self.lock.with { errors.append(error) }
                default: break
                }
            }

            // 清除好友邀請
            group.enter()
            self.clearFriendRequest(of: userID) { result in
                switch result {
                case .failure(let error):
                    self.lock.with { errors.append(error) }
                default: break
                }
            }

            // 若有陌生訊息，刪除雙方的陌生訊息（已經移至好友）
            group.enter()
            self.removeUnknownChat(ofUser: userID) { result in
                switch result {
                case .failure(let error):
                    self.lock.with { errors.append(error) }
                default: break
                }
                group.leave()
            }

            group.notify(queue: .main) {
                if errors.isEmpty {
                    completion(.success("Success"))
                } else {
                    completion(.failure(errors.first!))
                }
            }
        }
    }

    func addNewFriend(_ friend: SavedChat, toUser userID: UserID,
                      completion: @escaping (Result<String, Error>) -> Void) {

        let myNewFriendRef = UserFirestoreColEndpoint.friends(userID).ref.document(friend.id)
        firestoreManager.setData(friend.toDict, to: myNewFriendRef) { result in
            switch result {
            case .success:
                completion(.success("Success"))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func clearFriendRequest(of userID: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = myID else { return }
        var errors = [Error]()
        let group = DispatchGroup()

        // 從自己收到的邀請移除對方
        group.enter()
        let myRef = UserFirestoreColEndpoint.users.ref.document(myID)
        self.firestoreManager.removeValueFromArray(
            ref: myRef, field: UserDocField.User.receivedRequests, values: [userID]) { result in

            switch result {
            case .failure(let error):
                self.lock.with { errors.append(error) }
            default: break
            }
            group.leave()
        }

        // 從對方送出的邀請移除自己
        group.enter()
        let objectRef = UserFirestoreColEndpoint.users.ref.document(userID)
        self.firestoreManager.removeValueFromArray(
            ref: objectRef, field: UserDocField.User.sentRequests, values: [myID]) { result in

            switch result {
            case .failure(let error):
                self.lock.with { errors.append(error) }
            default: break
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success("Success"))
            } else {
                completion(.failure(errors.first!))
            }
        }
    }

    func removeUnknownChat(ofUser userID: UserID,
                           completion: @escaping (Result<String, Error>) -> Void) {

        guard let myID = myID else { return }
        var errors = [Error]()

        userQueue.async { [weak self] in
            guard let self = self else { return }
            let group = DispatchGroup()

            group.enter()
            let myUnknownRef = UserFirestoreColEndpoint.unknownChat(myID).ref.document(userID)
            self.firestoreManager.deleteDoc(ref: myUnknownRef) { result in
                switch result {
                case .failure(let error):
                    self.lock.with { errors.append(error) }
                default: break
                }

                group.leave()
            }

            group.enter()
            let userUnknownRef = UserFirestoreColEndpoint.unknownChat(userID).ref.document(myID)
            self.firestoreManager.deleteDoc(ref: userUnknownRef) { result in
                switch result {
                case .failure(let error):
                    self.lock.with { errors.append(error) }
                default: break
                }

                group.leave()
            }

            group.notify(queue: .main) {
                if errors.isEmpty {
                    completion(.success("Success"))
                } else {
                    completion(.failure(errors.first!))
                }
            }
        }
    }
}
