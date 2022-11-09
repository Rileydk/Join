//
//  FindPartnersTitles.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import Foundation

struct FindPartnersFormSections {
    static var sections = [basicSection, groupSection, detailSection]

    static let basicSection = SectionInfo(
        title: "專案資訊",
        buttonTitle: "下一步",
        items: [
            ItemInfo(
                name: "專案名稱", instruction: "至少5個字",
                must: true, type: .textField
            ),
            ItemInfo(
                name: "專案描述", instruction: "至少50個字",
                must: true, type: .textView
            ),
            ItemInfo(
                name: "專案類別", instruction: nil,
                must: true, type: .goNextButton
            )
        ]
    )

    static let groupSection = SectionInfo(
        title: "團隊與招募資訊",
        buttonTitle: "下一步",
        items: [
            ItemInfo(
                name: "團隊成員", instruction: nil,
                must: false, type: .addButton
            ),
            ItemInfo(
                name: "招募需求", instruction: nil,
                must: true, type: .addButton
            )
        ]
    )

    static let detailSection = SectionInfo(
        title: "最後一步了",
        // TODO: - 未來改為"預覽"
        buttonTitle: "發佈",
        items: [
            ItemInfo(
                name: "截止時間", instruction: nil,
                must: true, type: .goNextButton
            ),
            ItemInfo(
                name: "地點", instruction: nil,
                must: true, type: .goNextButton
            ),
            ItemInfo(
                name: "上傳封面照片", instruction: "<1MB",
                must: false, type: .uploadImage
            ),
            ItemInfo(
                name: "相關檔案或連結", instruction: nil,
                must: false, type: .addButton
            )
        ]
    )

    static let memberBranchButtonTitle = "完成"
    static let findPartnersNotFilledAlertTitle = "所有必填欄位都要填喔"
    static let memeberCardNotFilledAlertTitle = "所有欄位都要填喔"
    static let friendColumnWrongAlertTitle = "好友名稱輸入錯誤"
    static let alertActionTitle = "OK"

    static let noValidImageURLError = "No valid image url"
    static let noValidQuerysnapshotError = "No valid querysnapshot"
    static let notFriendError = "Not friend yet"
    static let noExistChatroomErrorDescription = "No exist chatroom"
    static let countIncorrectErrorDescription = "Messages count not match with users"
    static let decodeFailedErrorDescription = "Decode failed"
    // 這個似乎是錯誤的
    // static let datePickerLocale = "zh_TW"
}

struct SectionInfo: Equatable {
    let title: String
    let buttonTitle: String
    let items: [ItemInfo]

    static func == (lhs: SectionInfo, rhs: SectionInfo) -> Bool {
        lhs.title == rhs.title
    }
}

struct ItemInfo {
    let name: String
    let instruction: String?
    let must: Bool
    let type: InputType
}

enum InputType {
    case textField
    case textView
    case collapse
    case addButton
    case goNextButton
    case uploadImage
}
