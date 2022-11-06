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

enum NewProjectError: Error, LocalizedError {
    case noValidImageURLError

    var errorDescription: String {
        switch self {
        case .noValidImageURLError:
            return FindPartnersFormSections.newProjectNoValidImageURLErrorDescription
        }
    }
}

enum GetProjectError: Error, LocalizedError {
    case noValidQuerysnapshot

    var errorDescription: String {
        switch self {
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.getProjectErrorDescription
        }
    }
}

enum GetUserError: Error, LocalizedError {
    case noValidQuerysnapshot

    var errorDescription: String {
        switch self {
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.getUserErrorDescription
        }
    }
}

enum GetFriendError: Error, LocalizedError {
    case noValidQuerysnapshot
    case notFriendYet

    var errorDescription: String {
        switch self {
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.getUserErrorDescription
        case .notFriendYet:
            return FindPartnersFormSections.notFriendErrorDescription
        }
    }
}

enum GetMessageError: Error, LocalizedError {
    case noValidQuerysnapshot

    var errorDescription: String {
        switch self {
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.getMessageErrorDescription
        }
    }
}

enum FriendChatroomError: Error, LocalizedError {
    case noValidQuerysnapshot
    case noExistChatroom

    var errorDescription: String {
        switch self {
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.getFriendChatroomErrorDescription
        case .noExistChatroom:
            return FindPartnersFormSections.noFriendChatroomErrorDescription
        }
    }
}

enum UnknownChatroomError: Error, LocalizedError {
    case noValidQuerysnapshot
    case noExistChatroom

    var errorDescription: String {
        switch self {
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.getUnknownChatroomErrorDescription
        case .noExistChatroom:
            return FindPartnersFormSections.noUnknownChatroomErrorDescription
        }
    }
}

enum FirestoreEndpoint {
    case project
    case user
    case chatroom

    var ref: CollectionReference {
        switch self {
        case .project:
            return Firestore.firestore().collection("Project")
        case .user:
            return Firestore.firestore().collection("User")
        case .chatroom:
            return Firestore.firestore().collection("Chatroom")
        }
    }
}

class FirebaseManager {
    static let shared = FirebaseManager()
    private let firebaseQueue = DispatchQueue(label: "firebaseQueue", attributes: .concurrent)

    func uploadImage(image: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = Storage.storage().reference()
        let uuid = UUID()
        let imageRef = ref.child("\(uuid)")

        firebaseQueue.async {
            imageRef.putData(image) { (_, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }

                imageRef.downloadURL { (url, error) in
                    if let error = error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                    guard let downloadURL = url else {
                        DispatchQueue.main.async {
                            completion(.failure(NewProjectError.noValidImageURLError))
                        }
                        return
                    }
                    let urlString = "\(downloadURL)"
                    DispatchQueue.main.async {
                        completion(.success(urlString))
                    }
                }
            }
        }
    }

    // swiftlint:disable line_length
    func postNewProject(project: Project, image: UIImage?, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreEndpoint.project.ref
        var project = project

        if let image = image,
           let imageData = image.jpeg(.lowest) {

            firebaseQueue.async { [weak self] in
                self?.uploadImage(image: imageData) { result in

                    switch result {
                    case .success(let urlString):
                        project.imageURL = urlString

                        ref.addDocument(data: project.toDict) { error in
                            if let error = error {
                                DispatchQueue.main.async {
                                    completion(.failure(error))
                                }
                            } else {
                                DispatchQueue.main.async {
                                    completion(.success("Success"))
                                }
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
        } else {
            ref.addDocument(data: project.toDict) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.success("Success"))
                    }
                }
            }
        }
    }

    func getAllProjects(completion: @escaping (Result<[Project], Error>) -> Void) {
        firebaseQueue.async {
            let ref = FirestoreEndpoint.project.ref

            ref.getDocuments { querySnapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }

                var projects = [Project]()
                if let querySnapshot = querySnapshot {
                    for document in querySnapshot.documents {
                        do {
                            let project = try document.data(as: Project.self, decoder: Firestore.Decoder())
                            projects.append(project)
                        } catch {
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        completion(.success(projects))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(GetProjectError.noValidQuerysnapshot))
                    }
                }
            }
        }
    }

    func downloadImage(urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        firebaseQueue.async {
            let imageURLRef = Storage.storage().reference(forURL: urlString)

            imageURLRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }

                if let data = data,
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                }
            }
        }
    }

    func getUserInfo(id: UserID, completion: @escaping (Result<User, Error>) -> Void) {
        firebaseQueue.async {
            let ref = FirestoreEndpoint.user.ref

            ref.whereField("id", isEqualTo: id).getDocuments { querySnapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                if let querySnapshot = querySnapshot {
                    do {
                        let user = try querySnapshot.documents.first!.data(as: User.self, decoder: Firestore.Decoder())
                        DispatchQueue.main.async {
                            completion(.success(user))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(GetUserError.noValidQuerysnapshot))
                    }
                }
            }
        }
    }

    func checkIsFriend(id: UserID, completion: @escaping (Result<Friend, Error>) -> Void) {
        firebaseQueue.async {
            let ref = FirestoreEndpoint.user.ref
            ref.document(myAccount.id).collection("Friends").whereField("id", isEqualTo: id).getDocuments { (querySnapshot, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                        return
                    }
                }
                if querySnapshot != nil {
                    do {
                        if let friend = try querySnapshot?.documents.first?.data(as: Friend.self, decoder: Firestore.Decoder()) {
                            DispatchQueue.main.async {
                                completion(.success(friend))
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(.failure(GetFriendError.notFriendYet))
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(GetFriendError.noValidQuerysnapshot))
                    }
                }
            }
        }
    }

    func sendFriendRequest(to id: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        firebaseQueue.async {
            let ref = FirestoreEndpoint.user.ref
            ref.document(id).updateData(["receivedRequests": [myAccount.id]]) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                ref.document(myAccount.id).updateData(["sentRequests": [id]]) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        completion(.success("Success"))
                        return
                    }
                }
            }
        }
    }

    func acceptFriendRequest(from id: UserID, completion: @escaping (Result<String, Error>) -> Void) {
        firebaseQueue.async {
            let ref = FirestoreEndpoint.user.ref
            let group = DispatchGroup()
            group.enter()
            ref.document(myAccount.id).collection("Friends").document(id).setData(["id": id]) { error in
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
            ref.document(myAccount.id).updateData(["receivedRequests": FieldValue.arrayRemove([id])]) { error in
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
            ref.document(id).collection("Friends").document(myAccount.id).setData(["id": myAccount.id]) { error in
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
            ref.document(id).updateData(["sentRequests": FieldValue.arrayRemove([myAccount.id])]) { error in
                if let error  = error {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(error))
                    }
                    return
                }
                group.leave()
            }

            group.notify(queue: .main) {
                completion(.success("Success"))
            }
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
                if error as? GetFriendError == GetFriendError.notFriendYet {
                    self.checkUnknownChatroom(id: id) { [unowned self] result in
                        switch result {
                        case .success(let chatroomID):
                            completion(.success(chatroomID))
                        case .failure(let error):
                            if error as? UnknownChatroomError == UnknownChatroomError.noExistChatroom {
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
        firebaseQueue.async {
            let ref = FirestoreEndpoint.user.ref
            ref.document(myAccount.id).collection("UnknownChat").document(id).getDocument { (documentSnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let snapshot = documentSnapshot {
                    do {
                        let document = try snapshot.data(as: UnknownChat.self, decoder: Firestore.Decoder())
                        completion(.success(document.chatroomID))
                    } catch {
                        completion(.failure(UnknownChatroomError.noExistChatroom))
                    }
                } else {
                    completion(.failure(UnknownChatroomError.noValidQuerysnapshot))
                    return
                }
            }
        }

    }

    func createChatroom(id: UserID, type: ChatroomType, completion: @escaping (Result<ChatroomID, Error>) -> Void) {
        firebaseQueue.async {
            let chatroomRef = FirestoreEndpoint.chatroom.ref
            let documentID = chatroomRef.document().documentID
            let chatroom = Chatroom(id: documentID, member: [myAccount.id, id], messages: [])

            // 建立新的 chatroom
            chatroomRef.document(documentID).setData(chatroom.toInitDict) { [unowned self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
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
    }

    func saveChatroomID(to type: ChatroomType, id: UserID, chatroomID: ChatroomID, completion: @escaping (Result<String, Error>) -> Void ) {
        let userRef = FirestoreEndpoint.user.ref
        let collectionName = type.collectionName

        let group = DispatchGroup()
        group.enter()
        userRef.document(myAccount.id).collection(collectionName).document(id)
            .setData(["id": id, "chatroomID": chatroomID]) { error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                group.leave()
                return
            }
            group.leave()
        }
        group.enter()
        userRef.document(id).collection(collectionName).document(myAccount.id)
            .setData(["id": myAccount.id, "chatroomID": chatroomID]) { error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                group.leave()
                return
            }
            group.leave()
        }
        group.notify(queue: .main) {
            completion(.success("Success"))
        }
    }

    func getAllMessages(chatroomID: ChatroomID, completion: @escaping (Result<[Message], Error>) -> Void) {
        firebaseQueue.async {
            let ref = FirestoreEndpoint.chatroom.ref
            ref.document(chatroomID).collection("Messages").order(by: "time").getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let querySnapshot = querySnapshot {
                    let messages: [Message] = querySnapshot.documents.compactMap {
                        do {
                            return try $0.data(as: Message.self, decoder: Firestore.Decoder())
                        } catch {
                            completion(.failure(error))
                            return nil
                        }
                    }
                    completion(.success(messages))
                } else {
                    completion(.failure(GetMessageError.noValidQuerysnapshot))
                }
            }
        }
    }

    func addNewMessage() {

    }


    func getNewMessages() {

    }
}
