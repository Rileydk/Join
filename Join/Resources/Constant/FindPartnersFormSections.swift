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
        buttonTitle: "Next",
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
                name: "專案類別", subtitle: "選取專案類別", instruction: nil,
                note: "精準的專案類別，幫助我們推薦給感興趣的人", must: true, type: .goNextButton
            )
        ]
    )

    static let groupSection = SectionInfo(
        title: "招募與團隊資訊",
        buttonTitle: "Next",
        items: [
            ItemInfo(
                name: "招募對象", instruction: nil,
                must: true, type: .textFieldComboAmountPicker
            ),
            ItemInfo(
                name: "技術需求", instruction: nil,
                must: true, type: .textView
            ),
            ItemInfo(
                name: "團隊成員", subtitle: "選取團隊成員", instruction: nil,
                note: "讓其他人更了解你的團隊，並能快速建立工作群組", must: false, type: .goNextButton
            )
        ]
    )

    static let detailSection = SectionInfo(
        title: "最後一步了",
        buttonTitle: "Post",
        items: [
            ItemInfo(
                name: "截止時間", instruction: nil, note: "截止時間最晚為現在時間 1 小時後",
                must: true, type: .datePicker
            ),
            ItemInfo(
                name: "地點", instruction: nil,
                must: true, type: .textField
            ),
            ItemInfo(
                name: "上傳封面照片", instruction: "<1MB",
                must: true, type: .uploadImage
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
    static let noExistUser = "No exist user"
    static let notFriendError = "Not friend yet"
    static let noExistChatroomError = "No exist chatroom"
    static let noMessageError = "No Message"
    static let countIncorrectError = "Messages count not match with users"
    static let decodeFailedError = "Decode failed"
    static let nilResultError = "nil result"
    static let placeholderImage = "person.circle"
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
    var subtitle: String?
    let instruction: String?
    var note: String?
    let must: Bool
    let type: InputType
}

enum InputType {
    case textField
    case textView
    case textFieldComboAmountPicker
    case collapse
    case addButton
    case goNextButton
    case uploadImage
    case datePicker
}
