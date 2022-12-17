//
//  FirebaseStorageManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/17.
//

import Foundation
import FirebaseStorage

extension FirebaseManager {
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
}
