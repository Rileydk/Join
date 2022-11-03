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

enum FirestoreEndpoint {
    case project

    var ref: CollectionReference {
        switch self {
        case .project:
            return Firestore.firestore().collection("Project")
        }
    }
}

class FirebaseManager {
    static let shared = FirebaseManager()
    private let firebaseQueue = DispatchQueue(label: "firebaseQueue", attributes: .concurrent)

    func uploadImage(image: Data, completion: @escaping (String) -> Void) {
        let ref = Storage.storage().reference()
        let uuid = UUID()
        let imageRef = ref.child("\(uuid)")

        firebaseQueue.async {
            imageRef.putData(image) { (metadata, error) in
                print("current thread", Thread.current)
                guard let metadata = metadata else {
                    print("Metadata is nil")
                    return
                }
                imageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        print("No valid image download URL")
                        return
                    }
                    print("successfully upload, url is: ", downloadURL)
                    let urlString = "\(downloadURL)"
                    completion(urlString)
                }
            }
        }
    }

    func postNewProject(project: Project, image: UIImage?) {
        let ref = FirestoreEndpoint.project.ref
        var project = project

        if let image = image,
           let imageData = image.jpeg(.lowest) {
            uploadImage(image: imageData) { urlString in
                project.imageURL = urlString

                ref.addDocument(data: project.toDict) { error in
                    if let error = error {
                        print(error)
                    } else {
                        print("success")
                    }
                }
            }
        } else {
            ref.addDocument(data: project.toDict) { error in
                if let error = error {
                    print(error)
                } else {
                    print("success")
                }
            }
        }
    }

    func getAllProjects(completion: @escaping ([Project]) -> Void) {
        let ref = FirestoreEndpoint.project.ref
        ref.getDocuments { querySnapshot, error in
            if let error = error {
                print(error)
                return
            }

            var projects = [Project]()
            if let querySnapshot = querySnapshot {
                for document in querySnapshot.documents {
                    do {
                        let project = try document.data(as: Project.self, decoder: Firestore.Decoder())
                        projects.append(project)
                    } catch {
                        print(error)
                    }
                }
                completion(projects)
            } else {
                print("Not valid querysnapshot")
            }
        }
    }

    func downloadImage(urlString: String, completion: @escaping (UIImage) -> Void) {
        let imageURLRef = Storage.storage().reference(forURL: urlString)

        imageURLRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if let error = error {
                print(error)
            }

            if let data = data,
               let image = UIImage(data: data) {
                completion(image)
            }
        }
    }
}
