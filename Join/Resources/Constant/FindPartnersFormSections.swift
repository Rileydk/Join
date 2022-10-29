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
                must: true, type: .collapse
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
        buttonTitle: "預覽",
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
}

struct SectionInfo {
    let title: String
    let buttonTitle: String
    let items: [ItemInfo]
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
