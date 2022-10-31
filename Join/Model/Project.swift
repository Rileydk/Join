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
    var members: [User]?
    var recruiting = [Position]()
    var applicants = [User]()
}

struct Position {
    var title: String
    var skill: String
    var description: String
}
