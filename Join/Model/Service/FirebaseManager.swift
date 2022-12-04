// swiftlint:disable file_length
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

    var ref: CollectionReference {
        let db = Firestore.firestore()
        let users = db.collection("Users")

        let projects = "Project"
        let chatrooms = "Chatroom"
        let groupChats = "GroupChats"
        let groupChatrooms = "GroupChatrooms"
        let posts = "Posts"
        let friends = "Friends"
        let unknownChat = "UnknownChat"
        let messages = "Messages"
        let members = "Members"
        let infoCategories = "Categories"
        let reports = "Reports"

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
        }
    }
}

enum ProjectDocumentArrayFieldType: String {
    case applicants
    case collectors
}

enum FirestoreMyDocumentEndpoint {
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

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {}
    let myAuth = Auth.auth()
    var myID: String? {
        UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)
    }
    let firebaseQueue = DispatchQueue(label: "firebaseQueue", attributes: .concurrent)
    static let decoder = Firestore.Decoder()
    var newMessageListener: ListenerRegistration?

    func lookUpUser(userID: UserID, completion: @escaping (Result<JUser, Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref
        ref.document(userID).getDocument { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                do {
                    let user = try snapshot.data(as: JUser.self, decoder: FirebaseManager.decoder)
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

    func updateAuthentication(oldInfo: JUser, newInfo: JUser ,completion: @escaping (Result<String, Error>) -> Void) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        firebaseQueue.async { [weak self] in
            let group = DispatchGroup()
            if oldInfo.name != newInfo.name {
                group.enter()
                changeRequest?.displayName = newInfo.name
                changeRequest?.commitChanges { err in
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

            if oldInfo.email != newInfo.email {
                group.enter()
                self?.myAuth.currentUser?.updateEmail(to: newInfo.email) { err in
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

    func uploadImage(image: Data, completion: @escaping (Result<URLString, Error>) -> Void) {
        let ref = Storage.storage().reference()
        let uuid = UUID()
        let imageRef = ref.child("\(uuid)")

        imageRef.putData(image) { (_, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                }
                guard let downloadURL = url else {
                    completion(.failure(CommonError.noValidImageURLError))
                    return
                }
                let urlString = "\(downloadURL)"
                completion(.success(urlString))
            }
        }
    }

    // swiftlint:disable line_length
    func postNewProject(project: Project, image: UIImage?, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref
        let projectID = ref.document().documentID
        var project = project
        project.projectID = projectID
        project.createTime = Date()

        firebaseQueue.async {
            let group = DispatchGroup()
            group.enter()
            if let image = image,
               let imageData = image.jpeg(.lowest) {

                self.uploadImage(image: imageData) { result in
                    switch result {
                    case .success(let urlString):
                        project.imageURL = urlString

                        ref.document(projectID).setData(project.toDict) { error in
                            if let error = error {
                                group.leave()
                                group.notify(queue: .main) {
                                    completion(.failure(error))
                                }
                                return
                            }
                            group.leave()
                        }
                    case .failure(let error):
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(error))
                        }
                        return
                    }
                }
            } else {
                ref.document(projectID).setData(project.toDict) { error in
                    if let error = error {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(error))
                        }
                        return
                    }
                    group.leave()
                }
            }

            group.wait()
            group.enter()
            self.saveProjectIDToContact(projectID: projectID) { result in
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
                completion(.success("Success"))
            }
        }
    }

    func saveProjectIDToContact(projectID: ProjectID, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreMyDocumentEndpoint.myPosts.ref
        ref.document(projectID).setData(["projectID": projectID]) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success("Success"))
        }
    }

    func getAllProjects(completion: @escaping (Result<[Project], Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref

        let now = FirebaseFirestore.Timestamp(date: Date())
        ref.order(by: "createTime", descending: false).getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            var projects = [Project]()
            if let querySnapshot = querySnapshot {
                for document in querySnapshot.documents {
                    do {
                        let project = try document.data(as: Project.self, decoder: FirebaseManager.decoder)
                        projects.append(project)
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(projects))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func downloadImage(urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let imageURLRef = Storage.storage().reference(forURL: urlString)
        imageURLRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data,
               let image = UIImage(data: data) {
                completion(.success(image))
            } else {
                completion(.failure(CommonError.nilResult))
            }
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
                    let user = try querySnapshot.documents.first!.data(as: JUser.self, decoder: FirebaseManager.decoder)
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getSingleDocument<T: Decodable>(from ref: CollectionReference, match field: DocFieldName? = nil, with stringCondition: String? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        if let field = field, let stringCondition = stringCondition {
            ref.whereField(field.rawValue, isEqualTo: stringCondition).getDocuments { snapshot, err in
                if let err = err {
                    completion(.failure(err))
                    return
                }
                if snapshot != nil {
                    do {
                        if let decodedResult = try snapshot?.documents.first?.data(as: T.self, decoder: FirebaseManager.decoder) {
                            completion(.success(decodedResult))
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
    }

    func checkIsFriend(id: UserID, completion: @escaping (Result<Friend, Error>) -> Void) {
        let ref = FirestoreMyDocumentEndpoint.myFriends.ref
        ref.whereField("id", isEqualTo: id).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if querySnapshot != nil {
                do {
                    if let friend = try querySnapshot?.documents.first?.data(as: Friend.self, decoder: FirebaseManager.decoder) {
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

    func checkHasSentRequest(to id: UserID, completion: (Result<UserID, Error>) -> Void) {
        let ref = FirestoreMyDocumentEndpoint.mySentRequests.ref
        ref.whereField("id", isEqualTo: id).getDocuments { (snapshot, err) in
        }
    }

    func checkHasReceivedRequest(from id: UserID, completion: (Result<UserID, Error>) -> Void) {

    }

    func sendFriendRequest(to id: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let myDocRef = FirestoreEndpoint.users.ref.document(myID)
        firebaseQueue.async { [weak self] in
            let group = DispatchGroup()
            group.enter()
            let objectDocRef = FirestoreEndpoint.users.ref.document(id)
            objectDocRef.updateData(["receivedRequests": FieldValue.arrayUnion([myID])]) { error in
                if let error = error {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(error))
                    }
                    return
                }
                group.leave()
            }

            group.enter()
            myDocRef.updateData(["sentRequests": FieldValue.arrayUnion([id])]) { error in
                if let error = error {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(error))
                    }
                    return
                }
                group.leave()
            }
            group.notify(queue: .main) {
                completion(.success("Successfully send request!"))
            }
        }
    }

    func acceptFriendRequest(from id: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let myDocRef = FirestoreEndpoint.users.ref.document(myID)
        let friendDocRef = FirestoreEndpoint.users.ref.document(id)
        let group = DispatchGroup()
        group.enter()
        myDocRef.collection("Friends").document(id).setData(["id": id]) { error in
            if let error = error {
                group.leave()
                group.notify(queue: .main) {
                    completion(.failure(error))
                }
                return
            }
            group.leave()
        }

        group.enter()
        myDocRef.updateData(["receivedRequests": FieldValue.arrayRemove([id])]) { error in
            if let error  = error {
                group.leave()
                group.notify(queue: .main) {
                    completion(.failure(error))
                }
                return
            }
            group.leave()
        }

        group.enter()
        friendDocRef.collection("Friends").document(myID).setData(["id": myID]) { error in
            if let error  = error {
                group.leave()
                group.notify(queue: .main) {
                    completion(.failure(error))
                }
                return
            }
            group.leave()
        }

        group.enter()
        friendDocRef.updateData(["sentRequests": FieldValue.arrayRemove([myID])]) { error in
            if let error  = error {
                group.leave()
                group.notify(queue: .main) {
                    completion(.failure(error))
                }
                return
            }
            group.leave()
        }

        group.enter()
        self.checkUnknownChatroom(id: id) { [unowned self] result in
            switch result {
            case .success(let chatroom):
                self.move(unknownChat: chatroom, to: id) {
                    group.leave()
                }
            case .failure(let error):
                if error as? CommonError == CommonError.noExistChatroom {
                    group.leave()
                } else {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(error))
                    }
                    return
                }
            }
        }

        group.notify(queue: .main) {
            completion(.success("Success"))
        }
    }

    func getChatroom(id: UserID, completion: @escaping (Result<ChatroomID, Error>) -> Void) {
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
                    let document = try snapshot.data(as: SavedChat.self, decoder: FirebaseManager.decoder)
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

    func createChatroom(id: UserID, type: ChatroomType, completion: @escaping (Result<ChatroomID, Error>) -> Void) {
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
                let member = ChatroomMember(userID: $0, currentMemberStatus: .join, currentInoutStatus: .out, lastTimeInChatroom: Date())
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

    func saveChatroomID(to type: ChatroomType, id: UserID, chatroomID: ChatroomID, completion: @escaping (Result<String, Error>) -> Void ) {
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
        let myUnknownChatDocRef = ref.document(myID).collection(ChatroomType.unknown.collectionName).document(friend)
        let friendUnknownChatDocRef = ref.document(friend).collection(ChatroomType.unknown.collectionName).document(myID)
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

    func move(unknownChat: ChatroomID, to friend: UserID, completion: @escaping () -> Void) {
        saveChatroomID(to: .friend, id: friend, chatroomID: unknownChat) { [unowned self] result in
            switch result {
            case .success:
                removeUnknownChat(of: friend)
            case .failure(let error):
                print(error)
            }
            completion()
        }
    }

    func getMessages(of chatroomID: ChatroomID, completion: @escaping (Result<[Message], Error>) -> Void) {
        let ref = FirestoreEndpoint.chatrooms.ref
        ref.document(chatroomID).collection("Messages").order(by: "time").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let querySnapshot = querySnapshot {
                let messages: [Message] = querySnapshot.documents.compactMap {
                    do {
                        return try $0.data(as: Message.self, decoder: FirebaseManager.decoder)
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

    func addNewMessage(message: Message, chatroomID: ChatroomID, completion: @escaping (Result<String, Error>) -> Void) {
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

    func listenToNewMessages(chatroomID: ChatroomID, completion: @escaping (Result<[Message], Error>) -> Void) {
        let ref = FirestoreEndpoint.messages(chatroomID).ref
        newMessageListener = ref.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let querySnapshot = querySnapshot {
                let messages: [Message] = querySnapshot.documentChanges.compactMap {
                    do {
                        return try $0.document.data(as: Message.self, decoder: FirebaseManager.decoder)
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

    func getAllFriendsAndChatroomsInfo(type: ChatroomType, completion: @escaping (Result<[SavedChat], Error>) -> Void) {
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
                        return try $0.data(as: SavedChat.self, decoder: FirebaseManager.decoder)
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

    func getAllMatchedChatroomMessages(messagesList: [MessageListItem], completion: @escaping (Result<[MessageListItem], Error>) -> Void) {
        let chatrooms = messagesList.map { $0.chatroomID }
        var messagesList = messagesList

        firebaseQueue.async {
            let group = DispatchGroup()
            for i in 0 ..< chatrooms.count {
                group.enter()
                let ref = FirestoreEndpoint.messages(chatrooms[i]).ref
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
                                return try $0.data(as: Message.self, decoder: FirebaseManager.decoder)
                            } catch {
                                group.leave()
                                group.notify(queue: .main) {
                                    completion(.failure(error))
                                }
                                return nil
                            }
                        }

                        for item in messagesList {
                            if item.chatroomID == messagesList[i].chatroomID {
                                messagesList[i].messages = messages
                            }
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
                        return try $0.data(as: JUser.self, decoder: FirebaseManager.decoder)
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

    func getAllMessagesCombinedWithSender(type: ChatroomType, completion: @escaping (Result<[MessageListItem], Error>) -> Void) {
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
                    }.filter { !($0.chatroomID ?? "").isEmpty }
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
                    let infoContainer = try document.data(as: PersonalInfoContainer.self, decoder: FirebaseManager.decoder)
                    completion(.success(infoContainer.items))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func updatePersonalInfo(of type: InfoType, info: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = myID else { fatalError("Doesn't have myID") }
        let ref = FirestoreEndpoint.users.ref
        ref.document(myID).updateData([type.rawValue: info]) { err in
            if let err = err {
                completion(.failure(err))
            }
            completion(.success("Success"))
        }
    }

    func addNewWork(work: Work,completion: @escaping (Result<WorkID, Error>) -> Void ) {
        let ref = FirestoreMyDocumentEndpoint.myWorks.ref
        let workID = ref.document().documentID
        var work = work
        work.workID = workID
        work.latestUpdatedTime = Date()

        ref.document(workID).setData(work.toDict) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success(workID))
        }
    }

    func addNewRecords(records: [WorkRecord],to myWorkID: WorkID, completion: @escaping (Result<[RecordID], Error>) -> Void) {
        let ref = FirestoreMyDocumentEndpoint.myRecordsOfWork(myWorkID).ref
        let recordID = ref.document().documentID

        let group = DispatchGroup()
        var shouldContinue = true
        var recordsIDs = [RecordID]()
        for record in records {
            group.enter()
            guard shouldContinue else { return }
            let recordID = ref.document().documentID
            var record = record
            record.recordID = recordID
            ref.document(recordID).setData(record.toDict) { err in
                if let err = err {
                    group.leave()
                    shouldContinue = false
                    return
                }
                recordsIDs.append(recordID)
                group.leave()
            }
        }
        group.notify(queue: .main) {
            if shouldContinue {
                completion(.success(recordsIDs))
            } else {
//                completion(.failure(err))
            }
        }
    }

    func updateWorkRecordsOrder(of workID: WorkID, by ordersIDs: [RecordID], completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreMyDocumentEndpoint.myWorks.ref
        ref.document(workID).updateData(["recordsOrder": ordersIDs]) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success(workID))
        }
    }

    func getUserWorks(userID: UserID, completion: @escaping (Result<[Work], Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref.document(userID).collection("Works")
        ref.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
            }
            if let snapshot = snapshot {
                let works: [Work] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: Work.self, decoder: FirebaseManager.decoder)
                    } catch {
                        return nil
                    }
                }
                completion(.success(works))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getWorkRecords(userID: UserID, by workID: WorkID, completion: @escaping (Result<[WorkRecord], Error>) -> Void) {
//        let ref = FirestoreMyDocumentEndpoint.myRecordsOfWork(workID).ref
        let ref = FirestoreEndpoint.users.ref.document(userID).collection("Works").document(workID).collection("Records")
        ref.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
            }
            if let snapshot = snapshot {
                let workRecords: [WorkRecord] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: WorkRecord.self, decoder: FirebaseManager.decoder)
                    } catch {
                        return nil
                    }
                }
                completion(.success(workRecords))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getAllApplicants(projectID: ProjectID, applicantID: UserID, completion: @escaping (Result<[UserID], Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref
        ref.document(projectID).getDocument { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                do {
                    let project = try snapshot.data(as: Project.self, decoder: FirebaseManager.decoder)
                    completion(.success(project.applicants))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func applyForProject(projectID: ProjectID, applicantID: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref
        ref.document(projectID).updateData(["applicants": FieldValue.arrayUnion([applicantID])]) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success("Success"))
        }
    }

    func getAllMyProjectsItems(testID: String? = nil, completion: @escaping (Result<[ProjectItem], Error>) -> Void) {
//        var ref: CollectionReference
//        if let testID = testID {
//            ref = FirestoreEndpoint.users.ref.document(testID).collection("Posts")
//        } else {
//            ref = FirestoreMyDocumentEndpoint.myPosts.ref
//        }
        //////以上為測試
        let ref = FirestoreMyDocumentEndpoint.myPosts.ref
        ref.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let projectItems: [ProjectItem] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: ProjectItem.self, decoder: FirebaseManager.decoder)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }
                completion(.success(projectItems))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getAllMyProjects(projectsID: [ProjectID], completion: @escaping (Result<[Project], Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref
        ref.whereField("projectID", in: projectsID).getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let projects: [Project] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: Project.self, decoder: FirebaseManager.decoder)
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

    func getAllMyRelativeInfoInDocuments(type: ProjectDocumentArrayFieldType, completion: @escaping (Result<[Project], Error>) -> Void) {
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
                        return try $0.data(as: Project.self, decoder: FirebaseManager.decoder)
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

    func createGroupChatroom(groupChatroom: GroupChatroom, members: [ChatroomMember],completion: @escaping (Result<ChatroomID, Error>) -> Void) {
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

    func addNewGroupChatMembers(chatroomID: ChatroomID, selectedMembers: [ChatroomMember], completion: @escaping (Result<String, Error>) -> Void) {
        firebaseQueue.async { [weak self] in
            var allMembersIncludingExit = [ChatroomMember]()
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
                self?.updateGroupChatroomMemberStatus(setTo: .join, membersIDs: exitedMembersIDs, chatroomID: chatroomID, completion: { result in
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
                ref.document($0.userID).collection("GroupChats").document(chatroomID).setData(["chatroomID": chatroomID]) { err in
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

    func getAllGroupChatMembersIncludingExit(chatroomID: ChatroomID, completion: @escaping (Result<[ChatroomMember], Error>) -> Void) {
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
                        return try $0.data(as: ChatroomMember.self, decoder: FirebaseManager.decoder)
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

    func getAllCurrentGroupChatMembers(chatroomID: ChatroomID, completion: @escaping (Result<[UserID], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        ref.document(chatroomID).collection("Members").whereField("currentMemberStatus", isEqualTo: "join").getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let membersIDs: [UserID] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: ChatroomMember.self, decoder: FirebaseManager.decoder).userID
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

    func getGroupChatroomInfo(chatroomID: ChatroomID, completion: @escaping (Result<GroupChatroom, Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        ref.document(chatroomID).getDocument { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                do {
                    let chatroomInfo = try snapshot.data(as: GroupChatroom.self, decoder: FirebaseManager.decoder)
                    completion(.success(chatroomInfo))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func addNewGroupMessage(message: Message, chatroomID: ChatroomID, completion: @escaping (Result<String, Error>) -> Void) {
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

    func listenToNewGroupMessages(chatroomID: ChatroomID, completion: @escaping (Result<[Message], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupMessages(chatroomID).ref
        newMessageListener = ref.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let querySnapshot = querySnapshot {
                let messages: [Message] = querySnapshot.documentChanges.compactMap {
                    do {
                        return try $0.document.data(as: Message.self, decoder: FirebaseManager.decoder)
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
        let ref = FirestoreMyDocumentEndpoint.myGroupChat.ref
        ref.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let savedGroupChats: [SavedGroupChat] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: SavedGroupChat.self, decoder: FirebaseManager.decoder)
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

    func getAllMessagesCombinedWithEachGroup(messagesItems: [GroupMessageListItem], completion: @escaping (Result<[GroupMessageListItem], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        let chatroomIDs = messagesItems.map { $0.chatroomID }
        var messagesItems = messagesItems

        firebaseQueue.async {
            let group = DispatchGroup()
            for chatroomID in chatroomIDs {
                group.enter()
                ref.document(chatroomID).collection("Messages").order(by: "time", descending: true).getDocuments { (snapshot, err) in
                    if let err = err {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                    }
                    if let snapshot = snapshot {
                        let messages: [Message] = snapshot.documents.compactMap {
                            do {
                                return try $0.data(as: Message.self, decoder: FirebaseManager.decoder)
                            } catch {
                                group.leave()
                                group.notify(queue: .main) {
                                    completion(.failure(error))
                                }
                                return nil
                            }
                        }

                        for i in 0 ..< messagesItems.count {
                            if messagesItems[i].chatroomID == chatroomID {
                                messagesItems[i].messages = messages
                            }
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

    func getAllGroupMessages(completion: @escaping (Result<[GroupMessageListItem], Error>) -> Void) {
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
                        let chatroom = try $0.data(as: GroupChatroom.self, decoder: FirebaseManager.decoder)
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
                        return try $0.data(as: Message.self, decoder: FirebaseManager.decoder)
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
        firebaseQueue.async { [weak self] in
            guard let strongSelf = self else { return }
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

    func updatePrivateChatInoutStatus(setTo status: InoutStatus, chatroomID: ChatroomID, completion: @escaping (Result<String, Error>) -> Void) {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        let membersRef = FirestoreEndpoint.privateChatroomMembers(chatroomID).ref
        firebaseQueue.async { [weak self] in
            guard let strongSelf = self else { return }
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
                        let myMemberInfo = try snapshot.data(as: ChatroomMember.self, decoder: FirebaseManager.decoder)
                        for i in 0 ..< messagesItems.count {
                            if messagesItems[i].chatroomID == item.chatroomID {
                                messagesItems[i].lastTimeInChatroom = myMemberInfo.lastTimeInChatroom
                            }
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

    func getPrivateChatroomMembers(chatroomID: ChatroomID, completion: @escaping (Result<[ChatroomMember], Error>) -> Void) {
        let membersRef = FirestoreEndpoint.privateChatroomMembers(chatroomID).ref
        membersRef.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
            }
            if let snapshot = snapshot {
                let members: [ChatroomMember] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: ChatroomMember.self, decoder: FirebaseManager.decoder)
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

    func getMyLastTimeInChatroom(messagesItems: [MessageListItem], completion: @escaping (Result<[MessageListItem], Error>) -> Void) {
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
                        let myMemberInfo = try snapshot.data(as: ChatroomMember.self, decoder: FirebaseManager.decoder)
                        for i in 0 ..< messagesItems.count {
                            if messagesItems[i].chatroomID == item.chatroomID {
                                messagesItems[i].lastTimeInChatroom = myMemberInfo.lastTimeInChatroom
                            }
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
                    let user = try snapshot.data(as: JUser.self, decoder: FirebaseManager.decoder)
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

    func addNewValueToArray(ref: DocumentReference, field: String, values: [Any], completion: @escaping (Result<String, Error>) -> Void) {
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
                    let myProjectRef = FirestoreMyDocumentEndpoint.myPosts.ref
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
                                    let workRef = FirestoreEndpoint.users.ref.document(myID).collection("Works")
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
                        let myFriendsRef = FirestoreMyDocumentEndpoint.myFriends.ref
                        friendsIDs.forEach {
                            deleteFriendsGroup.enter()
                            self.deleteDocument(ref: myFriendsRef.document($0)) {
                                deleteFriendsGroup.leave()
                            }
                        }
                        // 刪除對方 user / Friends 紀錄下的自己及共同聊天室
                        friendsIDs.forEach {
                            deleteFriendsGroup.enter()
                            self.deleteDocument(ref: userRef.document($0).collection("Friends").document(myID)) {
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
                        self.deleteDocument(ref: userRef.document($0).collection("UnknownChat").document(myID)) {
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
                        let myGroupRef = FirestoreMyDocumentEndpoint.myGroupChat.ref
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
