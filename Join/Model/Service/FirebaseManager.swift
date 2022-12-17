//
//  FirestoreManager.swift
//  Join
//
//  Created by Riley Lai on 2022/11/1.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseFirestoreSwift
import FirebaseAuth

enum CommonError: Error, LocalizedError {
    case noValidImageURLError
    case noValidQuerysnapshot
    case decodeFailed
    case noExistUser
    case notFriendYet
    case countIncorrect
    case noExistChatroom
    case noMessage
    case nilResult

    var errorDescription: String {
        switch self {
        case .noValidImageURLError:
            return FindPartnersFormSections.noValidImageURLError
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.noValidQuerysnapshotError
        case .decodeFailed:
            return FindPartnersFormSections.decodeFailedError
        case .noExistUser:
            return FindPartnersFormSections.noExistUser
        case .notFriendYet:
            return FindPartnersFormSections.notFriendError
        case .countIncorrect:
            return FindPartnersFormSections.countIncorrectError
        case .noExistChatroom:
            return FindPartnersFormSections.noExistChatroomError
        case .noMessage:
            return FindPartnersFormSections.noMessageError
        case .nilResult:
            return FindPartnersFormSections.nilResultError
        }
    }
}

enum FirestoreEndpoint {
    case projects
    case users
    case chatrooms
    case groupChatroom
    case otherFriends(UserID)
    case otherUnknownChat(UserID)
    case otherGroupChat(UserID)
    case messages(ChatroomID)
    case groupMessages(ChatroomID)
    case privateChatroomMembers(ChatroomID)
    case groupMembers(ChatroomID)
    case interests
    case reports
    case works(UserID)
    case workRecords(UserID, WorkID)

    var ref: CollectionReference {
        let db = Firestore.firestore()
        let users = db.collection("Users")

        let projects = "Project"
        let chatrooms = "Chatroom"
        let groupChats = "GroupChats"
        let groupChatrooms = "GroupChatrooms"
        // let posts = "Posts"
        let friends = "Friends"
        let unknownChat = "UnknownChat"
        let messages = "Messages"
        let members = "Members"
        let infoCategories = "Categories"
        let reports = "Reports"
        let works = "Works"
        let workRecords = "Records"

        switch self {
        case .projects:
            return db.collection(projects)
        case .users:
            return users
        case .chatrooms:
            return db.collection(chatrooms)
        case .groupChatroom:
            return db.collection(groupChatrooms)
        case .otherFriends(let userID):
            return users.document(userID).collection(friends)
        case .otherUnknownChat(let userID):
            return users.document(userID).collection(unknownChat)
        case .otherGroupChat(let userID):
            return users.document(userID).collection(groupChats)
        case .messages(let chatroomID):
            return db.collection(chatrooms).document(chatroomID).collection(messages)
        case .groupMessages(let chatroomID):
            return db.collection(groupChatrooms).document(chatroomID).collection(messages)
        case .privateChatroomMembers(let chatroomID):
            return db.collection(chatrooms).document(chatroomID).collection(members)
        case .groupMembers(let chatroomID):
            return db.collection(groupChatrooms).document(chatroomID).collection(members)
        case .interests:
            return db.collection(infoCategories)
        case .reports:
            return db.collection(reports)
        case .works(let userID):
            return users.document(userID).collection(works)
        case .workRecords(let userID, let workID):
            return users.document(userID).collection(works).document(workID).collection(workRecords)
        }
    }
}

enum ProjectDocumentArrayFieldType: String {
    case applicants
    case collectors
}

enum FirestoreMyDocEndpoint {
    case myPosts
    case myFriends
    case mySentRequests
    case myUnknownChat
    case myGroupChat
    case myWorks
    case myRecordsOfWork(WorkID)

    var ref: CollectionReference {
        let db = Firestore.firestore()
        let users = db.collection("Users")
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("User ID doesn't exist")
        }
        let myDoc = users.document(myID)

        let sentRequests = "SentRequests"
        let posts = "Posts"
        let friends = "Friends"
        let unknownChat = "UnknownChat"
        let groupChats = "GroupChats"
        let works = "Works"
        let records = "Records"

        switch self {
        case .myPosts:
            return myDoc.collection(posts)
        case .myFriends:
            return myDoc.collection(friends)
        case .mySentRequests:
            return myDoc.collection(sentRequests)
        case .myUnknownChat:
            return myDoc.collection(unknownChat)
        case .myGroupChat:
            return myDoc.collection(groupChats)
        case .myWorks:
            return myDoc.collection(works)
        case .myRecordsOfWork(let workID):
            return myDoc.collection(works).document(workID).collection(records)
        }
    }
}

enum DocFieldName: String {
    case id
}

class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {}
    let myAuth = Auth.auth()
    var myID: String? {
        UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)
    }
    let firebaseQueue = DispatchQueue(label: "firebaseQueue", attributes: .concurrent)
    var newMessageListener: ListenerRegistration?

    func addNoneStopCollectionListener(to ref: CollectionReference, completion: @escaping () -> Void) {
        ref.addSnapshotListener { _, err in
            if let err = err {
                print(err)
                return
            }
            completion()
        }
    }

    func updateField(
        ref: DocumentReference, field: String, value: Any,
        completion: @escaping (Result<String, Error>) -> Void) {
        ref.updateData([field: value]) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success("Success"))
        }
    }

    func addNewValueToArray(
        ref: DocumentReference, field: String, values: [Any],
        completion: @escaping (Result<String, Error>) -> Void) {
        ref.updateData([field: FieldValue.arrayUnion(values)]) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success("Success"))
        }
    }

    func removeValueOfArray(ref: DocumentReference, field: String, values: [Any], completion: @escaping (Result<String, Error>) -> Void) {
        ref.updateData([field: FieldValue.arrayRemove(values)]) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success("Success"))
        }
    }

    func deleteDocument(ref: DocumentReference, completion: (() -> Void)? = nil) {
        ref.delete { err in
            if let err = err {
                print(err)
                completion?()
                return
            }
            completion?()
        }
    }

    func deleteChatroom(chatroomID: ChatroomID, completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        firebaseQueue.async {
            group.enter()
            // 刪除聊天室訊息
            self.getMessages(of: chatroomID) { result in
                switch result {
                case .success(let messages):
                    let messageRef = FirestoreEndpoint.messages(chatroomID).ref
                    messages.forEach { self.deleteDocument(ref: messageRef.document($0.messageID)) }
                    group.leave()
                case .failure(let err):
                    print(err)
                    group.leave()
                }
            }

            // 刪除聊天室成員
            group.enter()
            self.getPrivateChatroomMembers(chatroomID: chatroomID) { result in
                switch result {
                case .success(let members):
                    let membersRef = FirestoreEndpoint.privateChatroomMembers(chatroomID).ref
                    for member in members {
                        self.deleteDocument(ref: membersRef.document(member.userID))
                    }
                    group.leave()
                case .failure(let err):
                    print(err)
                    group.leave()
                }
            }

            // 刪除聊天室
            group.enter()
            let chatroomRef = FirestoreEndpoint.chatrooms.ref
            self.deleteDocument(ref: chatroomRef.document(chatroomID)) {
                group.leave()
            }

            group.notify(queue: .main) {
                print("success")
                completion?()
            }
        }
    }
}

// User Related
extension FirebaseManager {
    func lookUpUser(userID: UserID, completion: @escaping (Result<JUser, Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref
        ref.document(userID).getDocument { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                do {
                    let user = try snapshot.data(as: JUser.self)
                    completion(.success(user))
                } catch {
                    completion(.failure(CommonError.noExistUser))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
                return
            }
        }
    }

    func set(user: JUser, completion: @escaping (Result<JUser, Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref
        ref.document(user.id).setData(user.toDict) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success(user))
        }
    }

    func getUserInfo(id: UserID, completion: @escaping (Result<JUser, Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref
        ref.whereField("id", isEqualTo: id).getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let querySnapshot = querySnapshot {
                do {
                    let user = try querySnapshot.documents.first!.data(as: JUser.self)
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func checkIsFriend(id: UserID, completion: @escaping (Result<Friend, Error>) -> Void) {
        let ref = FirestoreMyDocEndpoint.myFriends.ref
        ref.whereField("id", isEqualTo: id).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if querySnapshot != nil {
                do {
                    if let friend = try querySnapshot?.documents.first?.data(as: Friend.self) {
                        completion(.success(friend))
                    } else {
                        completion(.failure(CommonError.notFriendYet))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getAllFriendsInfo(completion: @escaping (Result<[JUser], Error>) -> Void) {
        getAllFriendsAndChatroomsInfo(type: .friend) { [weak self] result in
            switch result {
            case .success(let friends):
                let usersID = friends.map { $0.id }
                guard !friends.isEmpty else {
                    completion(.success([]))
                    return
                }
                self?.getAllMatchedUsersDetail(usersID: usersID) { result in
                    switch result {
                    case .success(let usersDetail):
                        completion(.success(usersDetail))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getPersonalInfo(of type: InfoType, completion: @escaping (Result<[String], Error>) -> Void) {
        let ref = FirestoreEndpoint.interests.ref
        ref.document(type.rawValue).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let document = document {
                do {
                    let infoContainer = try document.data(as: PersonalInfoContainer.self)
                    completion(.success(infoContainer.items))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func updatePersonalInfo(
        of type: InfoType, info: [String],
        completion: @escaping (Result<String, Error>) -> Void) {
            guard let myID = myID else { fatalError("Doesn't have myID") }
            let ref = FirestoreEndpoint.users.ref
            ref.document(myID).updateData([type.rawValue: info]) { err in
                if let err = err {
                    completion(.failure(err))
                }
                completion(.success("Success"))
            }
        }

    func getAllMatchedUsersDetail(usersID: [UserID], completion: @escaping (Result<[JUser], Error>) -> Void) {
        let userRef = FirestoreEndpoint.users.ref
        userRef.whereField("id", in: usersID).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let snapshot = snapshot {
                let usersInfo: [JUser] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: JUser.self)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                completion(.success(usersInfo))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getAllMyRelativeInfoInDocuments(
        type: ProjectDocumentArrayFieldType,
        completion: @escaping (Result<[Project], Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let ref = FirestoreEndpoint.projects.ref
        let fieldName = type.rawValue

        ref.whereField(fieldName, arrayContains: myID).getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let projects: [Project] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: Project.self)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                completion(.success(projects))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getBlockList(completion: @escaping (Result<[UserID], Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref
        guard let myID = myID else { return }
        ref.document(myID).getDocument { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                do {
                    let user = try snapshot.data(as: JUser.self)
                    completion(.success(user.blockList))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func addNewReport(report: Report, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreEndpoint.reports.ref
        let reportID = ref.document().documentID
        var report = report
        report.reportID = reportID

        ref.document(reportID).setData(report.toDict) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success("Success"))
        }
    }
}
