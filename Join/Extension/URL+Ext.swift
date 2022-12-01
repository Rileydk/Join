//
//  URL+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/12/1.
//

import Foundation
import LinkPresentation

extension URL {
    func getMetadata(completion: @escaping (LPLinkMetadata?) -> Void) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: self) { (metadata, err) in
            guard err == nil, let metadata = metadata else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion(metadata)
            }
        }
    }
}
