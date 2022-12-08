//
//  FirestoreManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/7.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreManager {
    static let shared = FirestoreManager()
    private init() {}

    // MARK: - Methods

    func getDocument<T: Decodable>(_ docRef: DocumentReference, completion: @escaping (T?) -> Void) {
        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            completion(self.parseDocument(snapshot: snapshot, error: error))
        }
    }

    // get array of documents
    func getDocuments<T: Decodable>(_ query: Query, completion: @escaping ([T]) -> Void) {
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            completion(self.parseDocuments(snapshot: snapshot, error: error))
        }
    }

    // add new document to collection
    func setData(_ docData: [String: Any], to docRef: DocumentReference, completion: @escaping (Result<String, Error>) -> Void) {
        docRef.setData(docData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success("Success"))
        }
    }

    // update document field
    func addNewValueToArray(ref: DocumentReference, field: String, values: [Any], completion: @escaping (Result<String, Error>) -> Void) {
        ref.updateData([field: FieldValue.arrayUnion(values)]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success("Success"))
        }
    }

    // remove value from array
    func removeValueFromArray(ref: DocumentReference, field: String, values: [Any], completion: @escaping (Result<String, Error>) -> Void) {
        ref.updateData([field: FieldValue.arrayRemove(values)]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success("Success"))
        }
    }

    // delete document
    func deleteDoc(ref: DocumentReference, completion: @escaping (Result<String, Error>) -> Void) {
        ref.delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success("Success"))
        }
    }

    // add listener

    // remove listener

    // MARK: - Private
    private func parseDocument<T: Decodable>(snapshot: DocumentSnapshot?, error: Error?) -> T? {
        guard let snapshot = snapshot, snapshot.exists else {
            let errorMessage = error?.localizedDescription ?? ""
            print("Document nil:", errorMessage)
            return nil
        }

        var model: T?
        do {
            model = try snapshot.data(as: T.self)
        } catch {
            print("Error decoding \(T.self) data:", error.localizedDescription)
        }
        return model
    }

    private func parseDocuments<T: Decodable>(snapshot: QuerySnapshot?, error: Error?) -> [T] {
        guard let snapshot = snapshot else {
            let errorMessage = error?.localizedDescription ?? ""
            print("Snapshot nil:", errorMessage)
            return []
        }

        var models = [T]()
        snapshot.documents.forEach { document in
            do {
                let item = try document.data(as: T.self)
                models.append(item)
            } catch {
                print("Error decoding \(T.self) data:", error.localizedDescription)
            }
        }
        return models
    }
}
