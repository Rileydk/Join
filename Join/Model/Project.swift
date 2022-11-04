//
//  Project.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation
import UIKit

typealias URLString = String

struct Project: Hashable, Codable {
    var name: String = ""
    var description: String = ""
    var categories = [String]()
    // var deadline: Int64?
    var deadline: Date?
    var location = ""
    var imageURL: URLString?
    var members = [Member]()
    var recruiting = [OpenPosition]()
    var contact: UserId
    var applicants = [UserId]()

    static let mockProject = Project(contact: UserId(id: ""))

    var toDict: [String: Any] {
        let membersDict = members.map { $0.toDict }
        let recruitingDict = recruiting.map { $0.toDict }
        let applicantsDict = applicants.map { $0.toDict }
        let contactDict = contact.toDict

        return [
            "name": name as Any,
            "description": description as Any,
            "categories": categories as Any,
            "deadline": deadline as Any,
            "location": location as Any,
            "imageURL": imageURL as Any,
            "members": membersDict as Any,
            "recruiting": recruitingDict as Any,
            "contact": contactDict as Any,
            "applicants": applicantsDict as Any
        ]
    }
}

struct Member: Hashable, Codable {
    let id: String
    var role: String
    var skills: String

    var toDict: [String: Any] {
        return [
            "id": id as Any,
            "role": role as Any,
            "skills": skills as Any
        ]
    }
}

struct OpenPosition: Hashable, Codable {
    var role: String
    var skills: String
    var number: String

    var toDict: [String: Any] {
        return [
            "role": role as Any,
            "skills": skills as Any,
            "number": number as Any
        ]
    }
}
