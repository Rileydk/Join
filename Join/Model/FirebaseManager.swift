//
//  FirestoreManager.swift
//  Join
//
//  Created by Riley Lai on 2022/11/1.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

enum FirebaseEndpoint {
    case project

    var ref: CollectionReference {
        switch self {
        case .project:
            return Firestore.firestore().collection("Project")
        }
    }
}

struct FirebaseManager {
    func postNewProject(project: Project) {
        let ref = FirebaseEndpoint.project.ref
        ref.addDocument(data: project.toDict) { error in
            if let error = error {
                print(error)
            } else {
                print("success")
            }
        }
    }
}
