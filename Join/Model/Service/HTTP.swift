//
//  HTTP.swift
//  Join
//
//  Created by Riley Lai on 2022/11/24.
//

import Foundation

enum JHTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum JHTTPHeaderField: String {
    case contentType = "Content-Type"
}

enum JHTTPHeaderValue: String {
    case xwwwFormURLEncoded = "application/x-www-form-urlencoded"
}
