//
//  NSLock+Ext.swift
//  Join
//
//  Created by Riley Lai on 2022/12/8.
//

import Foundation

extension NSLock {
    @discardableResult
    func with<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
