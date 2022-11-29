//
//  Report.swift
//  Join
//
//  Created by Riley Lai on 2022/11/29.
//

import Foundation

typealias ReportID = String

struct Report {
    enum ContentType: String {
        case idea
        case personalProfile
    }

    var reportID: ReportID
    let type: ContentType
    let reportedObjectID: String
    let reportTime: Date?
    let reason: String?

    var toDict: [String: Any] {
        return [
            "reportID": reportID as Any,
            "type": type.rawValue as Any,
            "reportedObjectID": reportedObjectID as Any,
            "reportTime": reportTime as Any,
            "reason": reason as Any
        ]
    }
}
