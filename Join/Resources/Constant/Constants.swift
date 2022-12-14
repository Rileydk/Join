//
//  Constants.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import Foundation
import UIKit

struct Constant {
    struct FindIdeas {
        static let recruitingColumn = "招募中"
        static let skillsColumn = "技術需求"
        static let deadlineColumn = "截止時間"
        static let essentialLocationColumn = "合作地點"
        static let descriptionSectionTitle = "專案內容"
        static let contactSectionTitle = "聯絡人"
        static let applicantsSectionTitle = "應徵者"
        static let report = "檢舉此篇貼文"
        static let reportAlert = "確定要檢舉這篇貼文嗎？"
        static let reportResult = "已經收到您的檢舉"
        static let noApplicantAlertMessage = "目前尚無人應徵"

        static let projectsTopHorizontalScrollingContentInsets: NSDirectionalEdgeInsets =
            .init(top: 28, leading: 16, bottom: 20, trailing: 0)
        static let projectsPageContentInsets: NSDirectionalEdgeInsets =
            .init(top: 16, leading: 16, bottom: 20, trailing: 16)
        static let projectsInterGroupSpacing: CGFloat = 24
    }

    struct FindPartners {
        static let projectDescription = "請輸入專案詳細描述，讓申請者更了解你的專案"
        static let projectBasicSection = "專案基本資訊"
        static let projectNamePlaceholder = "請輸入專案名稱"
        static let recruitingFieldTitle = "招募對象"
        static let recruitingRolePlaceholder = "在團隊中擔任的角色"
        static let recruitingNumberFieldTitle = "人數"
        static let recruitingSkillsFieldTitle = "技術需求"
        static let recruitingSkillsPlaceholder = "清楚描述團隊需要的技術，是找到所需人才的秘訣"
        static let deadlineError = "截止時間不可晚於現在的 1 小時後"
    }

    struct Personal {
        enum EntryButtonsGroup: String, CaseIterable {
            case profile = "我的主頁"
            case myProject = "我的專案"
            case myApplications = "我的應徵"
        }

        static let sending = "發送中..."
        static let saveSuccessfully = "收藏成功"
        static let removeSuccessfully = "移除收藏"

        static let editPageTitle = "編輯我的個人資料"
        static let report = "檢舉此個人頁面"

        static let blockAlertTitle = "確定要封鎖此用戶嗎？"
        static let blockAlertMessage = """
            封鎖期間您將無法看到此用戶的個人頁面、所發佈的貼文\
            及您與該用戶間的歷史訊息，對方也不會顯示在您的好友列表中。\
            您隨時可以在個人頁面「我的黑名單」中變更此狀態。
            """
        static let blockAlertYesActionTitle = "我確定要封鎖"
        static let blockAlertCancelActionTitle = "取消"
        static let block = "封鎖此用戶"
        static let blocked = "已為您封鎖此用戶，您可以在個人頁面「個人設定」中查看及編輯"

        static let deleteFriend = "刪除好友"

        static let myFriends = "我的好友"
        static let myBlockList = "封鎖名單"
    }

    struct Portfolio {
        static let addPortfolio = "新增作品"
        static let sectionHeader = "作品集"
        static let uploadFile = "上傳附件"
        static let report = "檢舉此作品集"
    }

    struct Login {
        static let statement = "登入以使用完整功能\n登入即表示您同意我們的 "
        static let privatePolicy = "隱私權政策"
    }

    struct Edit {
        static let editIntroduction = "個人簡介"
        static let editSkills = "編輯我的技能"
        static let editInterests = "編輯我的興趣"
        static let addPortfolio = "新增我的作品"
    }

    struct Alert {
        static let longDurationProcess = "處理中，請勿關閉畫面"
    }

    struct Common {
        static let ok = "OK"
        static let confirm = "確定"
        static let cancel = "取消"
        static let save = "Save"
        static let processing = "處理中..."
        static let errorShouldRetry = "發生錯誤，請重新操作"
        static let notValidURL = "這不是有效的URL，請重新輸入"
        static let emptyURL = "URL不可為空白"
        static let duplicatedURL = "重複的URL"
    }

    struct Link {
        static let privacyPolicyURL = """
            https://www.privacypolicies.\
            com/live/d6a88da8-fa04-4360-a5b6-dafad6c03f26
            """
    }

    struct ImageRelated {
        static let fromLibrary = "從相簿選取"
        static let openCamera = "開啟相機"
        static let scanDocument = "掃描文件或圖片"
        static let pasteURL = "貼上網址（請先複製）"
    }

    struct AppleIdentifier {
        static let sectionHeaderElementKind = "section-header-element-kind"
        static let sectionFooterElementKind = "section-footer-element-kind"
    }

    struct ColorTheme {
        static let lightBackgroundColor = UIColor.Gray6
        static let darkBackgroundColor = UIColor.Blue1
    }
}
