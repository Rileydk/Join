
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

struct FirebaseManager {
    func uploadImage(image: Data) {
        let ref = Storage.storage().reference()
        let imageRef = ref.child("image1")
        imageRef.putData(image) { (metadata, error) in
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
            }
        }
    }

    func postNewProject(project: Project) {
        let ref = FirestoreEndpoint.project.ref
        ref.addDocument(data: project.toDict) { error in
            if let error = error {
                print(error)
            } else {
                print("success")
            }
        }
    }

    func downloadImage(urlString: String) {
        let httpsRef = Storage.storage().reference(forURL: urlString)

        httpsRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) in
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
