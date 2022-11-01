//
//  User.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation

struct User {
    let id: String

    var toDict: [String: Any] {
        return [
            "id": id as Any
        ]
    }
}
