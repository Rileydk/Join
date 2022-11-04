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

enum NewProject: Error, LocalizedError {
    case noValidImageURLError

    var errorDescription: String {
        switch self {
        case .noValidImageURLError:
            return FindPartnersFormSections.newProjectNoValidImageURLErrorDescription
        }
    }
}

enum GetProject: Error, LocalizedError {
    case noValidQuerysnapshot

    var errorDescription: String {
        switch self {
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.getProjectErrorDescription
        }
    }
}

enum GetUser: Error, LocalizedError {
    case noValidQuerysnapshot

    var errorDescription: String {
        switch self {
        case .noValidQuerysnapshot:
            return FindPartnersFormSections.getUserErrorDescription
        }
    }
}

enum FirestoreEndpoint {
    case project
    case user

    var ref: CollectionReference {
        switch self {
        case .project:
            return Firestore.firestore().collection("Project")
        case .user:
            return Firestore.firestore().collection("User")
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
                            completion(.failure(NewProject.noValidImageURLError))
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
        let ref = FirestoreEndpoint.project.ref
        firebaseQueue.async {
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
                        completion(.failure(GetProject.noValidQuerysnapshot))
                    }
                }
            }
        }
    }

    func downloadImage(urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let imageURLRef = Storage.storage().reference(forURL: urlString)

        firebaseQueue.async {
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

    func getUserInfo(user: UserId, completion: @escaping (Result<User, Error>) -> Void) {
        let ref = FirestoreEndpoint.user.ref

        firebaseQueue.async {
            ref.whereField("id", isEqualTo: user.id).getDocuments { querySnapshot, error in
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
                        completion(.failure(GetUser.noValidQuerysnapshot))
                    }
                }
            }
        }
    }
}
