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

enum CommonError: Error, LocalizedError {
    case noValidImageURLError
    case noValidQuerysnapshot
    case decodeFailed
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
    case myPosts
    case myFriends
    case myUnknownChat
    case myGroupChat
    case otherFriends(UserID)
    case otherUnknownChat(UserID)
    case messages(ChatroomID)
    case groupMessages(ChatroomID)
    case interests

    var ref: CollectionReference {
        let db = Firestore.firestore()
        let users = db.collection("User")
        let myDoc = users.document(myAccount.id)

        let projects = "Project"
        let chatrooms = "Chatroom"
        let myGroupChats = "GroupChats"
        let groupChatrooms = "GroupChatrooms"
        let posts = "Posts"
        let friends = "Friends"
        let unknownChat = "UnknownChat"
        let messages = "Messages"
        let interests = "Categories"

        switch self {
        case .projects:
            return db.collection(projects)
        case .users:
            return users
        case .chatrooms:
            return db.collection(chatrooms)
        case .groupChatroom:
            return db.collection(groupChatrooms)
        case .myPosts:
            return myDoc.collection(posts)
        case .myFriends:
            return myDoc.collection(friends)
        case .myUnknownChat:
            return myDoc.collection(unknownChat)
        case .myGroupChat:
            return myDoc.collection(myGroupChats)
        case .otherFriends(let userID):
            return users.document(userID).collection(friends)
        case .otherUnknownChat(let userID):
            return users.document(userID).collection(unknownChat)
        case .messages(let chatroomID):
            return db.collection(chatrooms).document(chatroomID).collection(messages)
        case .groupMessages(let chatroomID):
            return db.collection(groupChatrooms).document(chatroomID).collection(messages)
        case .interests:
            return db.collection(interests)
        }
    }
}

// swiftlint:disable type_body_length
class FirebaseManager {
    static let shared = FirebaseManager()
    let firebaseQueue = DispatchQueue(label: "firebaseQueue", attributes: .concurrent)
    static let decoder = Firestore.Decoder()
    var newMessageListener: ListenerRegistration?

    func uploadImage(image: Data, completion: @escaping (Result<URLString, Error>) -> Void) {
        let ref = Storage.storage().reference()
        let uuid = UUID()
        let imageRef = ref.child("\(uuid)")

        imageRef.putData(image) { (_, error) in
            if let error = error {
                completion(.failure(error))
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
        let ref = FirestoreEndpoint.myPosts.ref
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
        ref.whereField("deadline", isGreaterThan: now).order(by: "deadline", descending: true).getDocuments { querySnapshot, error in
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

    func getUserInfo(id: UserID, completion: @escaping (Result<User, Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref
        ref.whereField("id", isEqualTo: id).getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let querySnapshot = querySnapshot {
                do {
                    let user = try querySnapshot.documents.first!.data(as: User.self, decoder: FirebaseManager.decoder)
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
        let ref = FirestoreEndpoint.myFriends.ref
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

    func sendFriendRequest(to id: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        let myDocRef = FirestoreEndpoint.users.ref.document(id)
        myDocRef.updateData(["receivedRequests": [myAccount.id]]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            myDocRef.updateData(["sentRequests": [id]]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success("Success"))
                return
            }
        }
    }

    func acceptFriendRequest(from id: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        let myDocRef = FirestoreEndpoint.users.ref.document(myAccount.id)
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
        friendDocRef.collection("Friends").document(myAccount.id).setData(["id": myAccount.id]) { error in
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
        friendDocRef.updateData(["sentRequests": FieldValue.arrayRemove([myAccount.id])]) { error in
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
        let myDocRef = FirestoreEndpoint.users.ref.document(myAccount.id)
        myDocRef.collection("UnknownChat").document(id).getDocument { (documentSnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let snapshot = documentSnapshot {
                do {
                    let document = try snapshot.data(as: SavedChat.self, decoder: FirebaseManager.decoder)
                    completion(.success(document.chatroomID))
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
        let chatroomRef = FirestoreEndpoint.chatrooms.ref
        let documentID = chatroomRef.document().documentID
        let chatroom = Chatroom(id: documentID, member: [myAccount.id, id], messages: [])

        // 建立新的 chatroom
        chatroomRef.document(documentID).setData(chatroom.toInitDict) { [unowned self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            // 分別存入 friend 或 unknownchatroom 中
            self.saveChatroomID(to: type, id: id, chatroomID: documentID) { result in
                switch result {
                case .success:
                    completion(.success(documentID))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func saveChatroomID(to type: ChatroomType, id: UserID, chatroomID: ChatroomID, completion: @escaping (Result<String, Error>) -> Void ) {
        let myDocRef = FirestoreEndpoint.users.ref.document(myAccount.id)
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
        friendDocRef.collection(collectionName).document(myAccount.id)
            .setData(["id": myAccount.id, "chatroomID": chatroomID]) { error in
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
        let myUnknownChatDocRef = ref.document(myAccount.id).collection(ChatroomType.unknown.collectionName).document(friend)
        let friendUnknownChatDocRef = ref.document(friend).collection(ChatroomType.unknown.collectionName).document(myAccount.id)
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
        let ref = FirestoreEndpoint.users.ref.document(myAccount.id).collection(type.collectionName)
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

    func getAllMatchedChatroomMessages(chatrooms: [ChatroomID], completion: @escaping (Result<[Message], Error>) -> Void) {
        var messages = [Message]()

        let group = DispatchGroup()
        for i in 0 ..< chatrooms.count {
            group.enter()
            let ref = FirestoreEndpoint.messages(chatrooms[i]).ref
            ref.order(by: "time", descending: true).limit(to: 1).getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let snapshot = snapshot {
                    guard let lastMessage = snapshot.documents.first else {
                        completion(.failure(CommonError.noMessage))
                        return
                    }
                    do {
                        let message = try lastMessage.data(as: Message.self, decoder: FirebaseManager.decoder)
                        messages.append(message)
                    } catch {
                        completion(.failure(error))
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(.success(messages))
        }
    }

    func getAllMatchedUsersDetail(usersID: [UserID], completion: @escaping (Result<[User], Error>) -> Void) {
        let userRef = FirestoreEndpoint.users.ref
        userRef.whereField("id", in: usersID).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let snapshot = snapshot {
                let usersInfo: [User] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: User.self, decoder: FirebaseManager.decoder)
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

    func getAllLatestMessages(type: ChatroomType, completion: @escaping (Result<[MessageListItem], Error>) -> Void) {
        getAllFriendsAndChatroomsInfo(type: type) { [weak self] result in
            switch result {
            // 取得所有存放在 user 下符合類別的 chatroom
            case .success(let savedChat):
                let chatroomsID = savedChat.map { $0.chatroomID }
                let usersID = savedChat.map { $0.id }
                var messages = [Message]()
                var users = [User]()

                guard !chatroomsID.isEmpty else {
                    completion(.success([]))
                    return
                }

                let group = DispatchGroup()
                group.enter()
                self?.getAllMatchedChatroomMessages(chatrooms: chatroomsID) { result in
                    switch result {
                    case .success(let latestMessages):
                        messages = latestMessages
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    group.leave()
                }
                group.enter()
                self?.getAllMatchedUsersDetail(usersID: usersID) { result in
                    switch result {
                    case .success(let usersDetail):
                        users = usersDetail
                    case .failure(let error):
                        print(error)
                    }
                    group.leave()
                }
                group.notify(queue: .main) {
                    if messages.count != users.count {
                        completion(.failure(CommonError.countIncorrect))
                    } else {
                        var latestMessageList = [MessageListItem]()
                        for i in 0 ..< messages.count {
                            latestMessageList += [
                                MessageListItem(
                                    userID: users[i].id,
                                    latestMessage: messages[i],
                                    chatroomID: chatroomsID[i]
                            )]
                        }
                        completion(.success(latestMessageList))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getAllFriendsInfo(completion: @escaping (Result<[User], Error>) -> Void) {
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

    func getAllInterests(completion: @escaping (Result<[String], Error>) -> Void) {
        let ref = FirestoreEndpoint.interests.ref
        ref.document("interests").getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let document = document {
                do {
                    let interestsContainer = try document.data(as: Interest.self, decoder: FirebaseManager.decoder)
                    completion(.success(interestsContainer.interests))
                } catch {
                    completion(.failure(error))
                }
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

    func getAllMyProjectsID(completion: @escaping (Result<[ProjectItem], Error>) -> Void) {
        let ref = FirestoreEndpoint.myPosts.ref
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

    func getAllMyApplications(completion: @escaping (Result<[Project], Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref
        ref.whereField("applicants", arrayContains: myAccount.id).getDocuments { (snapshot, err) in
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

    func createGroupChatroom(groupChatroom: GroupChatroom, completion: @escaping (Result<ChatroomID, Error>) -> Void) {
        let groupChatroomsRef = FirestoreEndpoint.groupChatroom.ref
        let chatroomID = groupChatroomsRef.document().documentID
        var groupChatroom = groupChatroom
        groupChatroom.id = chatroomID

        firebaseQueue.async {
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
            groupChatroom.members.forEach {
                group.enter()
                let ref = FirestoreEndpoint.users.ref
                ref.document($0.id).collection("GroupChats").document(chatroomID).setData(["chatroomID": chatroomID]) { err in
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
                completion(.success(chatroomID))
            }
        }
    }

    func addNewGroupChatMembers(members: [GroupChatMember], completion: @escaping (Result<String, Error>) -> Void) {

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
        let ref = FirestoreEndpoint.myGroupChat.ref
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

    func getAllLatestGroupMessages(chatroomIDs: [ChatroomID], completion: @escaping (Result<[GroupMessageListItem], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        let group = DispatchGroup()
        var groupMessageListItem = [GroupMessageListItem]()

        for chatroomID in chatroomIDs {
            group.enter()
            ref.document(chatroomID).collection("Messages").order(by: "time", descending: true).limit(to: 1).getDocuments { (snapshot, err) in
                if let err = err {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                }
                if let snapshot = snapshot {
                    do {
                        if let message = try snapshot.documents.first?.data(as: Message.self, decoder: FirebaseManager.decoder) {
                            groupMessageListItem.append(GroupMessageListItem(chatroomID: chatroomID, latestMessage: message))
                        } else {
                            group.notify(queue: .main) {
                                completion(.failure(CommonError.noMessage))
                            }
                        }
                        group.leave()
                    } catch {
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(error))
                        }
                    }
                } else {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(CommonError.noValidQuerysnapshot))
                    }
                }
            }
        }
        group.notify(queue: .main) {
            completion(.success(groupMessageListItem))
        }
    }

    func getAllGroupChatroomInfo(messagesItems: [GroupMessageListItem], completion: @escaping (Result<[GroupMessageListItem], Error>) -> Void) {
        let ref = FirestoreEndpoint.groupChatroom.ref
        let chatroomIDs = messagesItems.map { $0.chatroomID }
        var chatroomsDetails = messagesItems

        guard !messagesItems.isEmpty else {
            completion(.failure(CommonError.noMessage))
            return
        }

        ref.whereField("id", in: chatroomIDs).getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let chatrooms: [GroupChatroom] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: GroupChatroom.self, decoder: FirebaseManager.decoder)
                    } catch {
                        completion(.failure(error))
                        return nil
                    }
                }

                for chatroom in chatrooms {
                    for i in 0 ..< messagesItems.count where chatroom.id == messagesItems[i].chatroomID {
                        chatroomsDetails[i].chatroom = chatroom
                    }
                }
                completion(.success(chatroomsDetails))
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
}
