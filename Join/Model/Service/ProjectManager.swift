//
//  ProjectManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/17.
//

import Foundation
import UIKit
import FirebaseFirestore

extension FirebaseManager {
    func postNewProject(
        project: Project, image: UIImage?,
        completion: @escaping (Result<String, Error>) -> Void) {
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
        let ref = FirestoreMyDocEndpoint.myPosts.ref
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

        ref.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            var projects = [Project]()
            if let querySnapshot = querySnapshot {
                for document in querySnapshot.documents {
                    do {
                        let project = try document.data(as: Project.self)
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

    func getProject(projectID: ProjectID, completion: @escaping (Result<Project, Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref.document(projectID)
        ref.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let snapshot = snapshot {
                do {
                    let project = try snapshot.data(as: Project.self)
                    completion(.success(project))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getAllApplicants(
        projectID: ProjectID, applicantID: UserID,
        completion: @escaping (Result<[UserID], Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref
        ref.document(projectID).getDocument { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                do {
                    let project = try snapshot.data(as: Project.self)
                    completion(.success(project.applicants))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func applyForProject(
        projectID: ProjectID, applicantID: UserID,
        completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreEndpoint.projects.ref
        ref.document(projectID).updateData(["applicants": FieldValue.arrayUnion([applicantID])]) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success("Success"))
        }
    }

    func getAllMyProjectsItems(
        testID: String? = nil,
        completion: @escaping (Result<[ProjectItem], Error>) -> Void) {
        let ref = FirestoreMyDocEndpoint.myPosts.ref
        ref.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            if let snapshot = snapshot {
                let projectItems: [ProjectItem] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: ProjectItem.self)
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
}
