
//
//  FirestoreManager.swift
//  Join
//
//  Created by Riley Lai on 2022/11/1.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

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
    let firebaseQueue = DispatchQueue(label: "firebaseQueue", attributes: .concurrent)
    static let shared = FirebaseManager()

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
            print("including image")
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
            print("without image")
            ref.addDocument(data: project.toDict) { error in
                if let error = error {
                    print(error)
                } else {
                    print("success")
                }
            }
        }
    }

    func downloadImage(urlString: String) {
        let imageURLRef = Storage.storage().reference(forURL: urlString)

        imageURLRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if let error = error {
                print(error)
            }

            if let data = data {
                let image = UIImage(data: data)
                print("downloaded", image)
            }
        }
    }
}
