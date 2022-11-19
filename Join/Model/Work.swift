//
//  Masterpiece.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import Foundation

typealias WorkID = String
typealias RecordID = String

struct Work: Hashable {
    var workID: WorkID
    var name: String
    var description: String?
    var recordsOrder = [RecordID]()
    var latestUpdatedTime: Date
    var creator: UserID

    var toDict: [String: Any] {
        return [
            "workID": workID as Any,
            "name": name as Any,
            "description": description as Any,
            "recordsOrder": recordsOrder as Any,
            "latestUpdatedTime": latestUpdatedTime as Any,
            "creator": creator as Any
        ]
    }
}

struct WorkRecord: Hashable {
    var recordID: RecordID
    var url: URLString

    var toDict: [String: Any] {
        return [
            "recordID": recordID as Any,
            "url": url as Any
        ]
    }
}

struct WorkItem {
    var workID: WorkID
    var name: String
    var description: String?
    var latestUpdatedTime: Date
    var records: [WorkRecord]
}
