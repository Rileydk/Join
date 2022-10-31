//
//  Project.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import Foundation
import UIKit

struct Project {
    var name: String = ""
    var description: String = ""
    var categories = [String]()
//    let deadline: Date
//    let location:
    var image: UIImage?
    var members = [User]()
    var recruiting = [OpenPosition]()
    var applicants = [User]()
}

struct Member {
    let id: String
    var role: String
    var skills: [String]
}

struct OpenPosition {
    var role: String
    var skill: [String]
    var description: String
    var number: Int
}