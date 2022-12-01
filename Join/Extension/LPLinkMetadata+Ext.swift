//
//  LPLinkMetadata+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/12/1.
//

import Foundation
import LinkPresentation

extension LPLinkMetadata {
    func getMetadataImage(completion: @escaping (UIImage?) -> Void) {
        guard let imageProvider = self.imageProvider else { return }
        imageProvider.loadObject(ofClass: UIImage.self) { (image, err) in
            if let err = err {
                print(err)
                completion(nil)
                return
            }
            if let image = image as? UIImage {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                completion(nil)
            }
        }
    }
}
