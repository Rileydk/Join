//
//  JoinDateExtTests.swift
//  JoinTests
//
//  Created by Riley Lai on 2022/12/8.
//

import XCTest
@testable import Join

class DateExtensionTests: XCTestCase {

    var sut: Date!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = Date(timeIntervalSinceReferenceDate: -123456789.0)
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testDateFormatted() {
        XCTAssertEqual(sut.formatted, "1997-02-02 10:26", "Date formatted extension incorrect")
    }

}
