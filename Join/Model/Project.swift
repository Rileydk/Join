//
//  Project.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation
import UIKit

typealias URLString = String
typealias ProjectID = String

struct Project: Hashable, Codable {
    var projectID: ProjectID = ""
    var name: String = ""
    var description: String = ""
    var categories = [String]()
    // var deadline: Int64?
    var deadline: Date?
    var location = ""
    var imageURL: URLString?
    var members = [Member]()
    var recruiting = [OpenPosition]()
    var contact: UserID
    var applicants = [UserID]()

    static let mockProject = Project(contact: "")

    var toDict: [String: Any] {
        let membersDict = members.map { $0.toDict }
        let recruitingDict = recruiting.map { $0.toDict }

        return [
            "projectID": projectID as Any,
            "name": name as Any,
            "description": description as Any,
            "categories": categories as Any,
            "deadline": deadline as Any,
            "location": location as Any,
            "imageURL": imageURL as Any,
            "members": membersDict as Any,
            "recruiting": recruitingDict as Any,
            "contact": contact as Any,
            "applicants": applicants as Any
        ]
    }
}

struct ProjectItem: Codable {
    let projectID: ProjectID
}

struct Member: Hashable, Codable {
    var id: UserID?
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

struct Interest: Codable {
    var interests = [String]()
}
