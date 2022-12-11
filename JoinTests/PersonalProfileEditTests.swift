//
//  PersonalProfileEditTests.swift
//  JoinTests
//
//  Created by Riley Lai on 2022/12/9.
//

import XCTest
@testable import Join

class PersonalProfileEditTests: XCTestCase {
    enum StubbedUser {
        case emptyUser
        case emptyName
        case emptyEmail
        case filledUser
        
        var data: JUser {
            switch self {
            case .emptyUser: return JUser(id: "", name: "", email: "")
            case .emptyName: return JUser(id: "", name: "Fake name", email: "")
            case .emptyEmail: return JUser(id: "", name: "", email: "Fake email")
            case .filledUser: return JUser(id: "", name: "Fake name", email: "Fake email")
            }
        }
    }

    var sut: PersonalProfileEditViewController!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = PersonalProfileEditViewController()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testEmptyUserShouldNotSave() throws {
        let stubbedUser: StubbedUser = .emptyUser
        sut.user = stubbedUser.data
        XCTAssertTrue(!sut.isSavable(), "User empty should not be able to save")
    }

    func testEmptyNameUserShouldNotSave() {
        let stubbedUser: StubbedUser = .emptyName
        sut.user = stubbedUser.data
        XCTAssertTrue(!sut.isSavable(), "User empty should not be able to save")
    }

    func testEmptyEmailUserShouldNotSave() {
        let stubbedUser: StubbedUser = .emptyEmail
        sut.user = stubbedUser.data
        XCTAssertTrue(!sut.isSavable(), "User empty should not be able to save")
    }

    func testFilledUserCanSave() {
        let stubbedUser: StubbedUser = .filledUser
        sut.user = stubbedUser.data
        XCTAssertTrue(sut.isSavable(), "User empty should not be able to save")
    }
}
