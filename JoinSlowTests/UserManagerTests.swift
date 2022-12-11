//
//  UserManagerTests.swift
//  JoinTests
//
//  Created by Riley Lai on 2022/12/9.
//

import XCTest
@testable import Join

class UserManagerTests: XCTestCase {

    var sut: UserManager!
    let networkMonitor = NetworkMonitor.shared

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = UserManager.shared
    }

    override func tearDownWithError() throws {
        sut = nil
        networkMonitor.stopMonitoring()
        try super.tearDownWithError()
    }

    func testGetUserInfoOfMySelf() throws {
        try XCTSkipUnless(networkMonitor.isReachable, "Network is unreachable")
        let myID = try XCTUnwrap(UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey))

        let promise = expectation(description: "Got my user info!")
        sut.getSingleUserData(userID: myID) { user in
            promise.fulfill()
            if let user = user {
                XCTAssertEqual(myID, user.id, "Get the wrong user info")
            } else {
                XCTFail("Error: My user info is nil")
            }
        }
        wait(for: [promise], timeout: 5)
    }
}
