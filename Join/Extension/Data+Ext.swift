//
//  Data+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/11/24.
//

import Foundation

extension Data {
    func urlSafeBase64EncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
