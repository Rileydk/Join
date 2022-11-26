//
//  Constants.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import Foundation

struct Constant {
    struct Placeholder {
        static let coverURLString = "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/F5986CC3-D3EF-4408-AC79-D9D7FC1F8450?alt=media&token=44e11625-5d08-46c7-a8ac-90737e656591"
    }

    struct FindIdeas {
        static let recruitingColumn = "招募中"
        static let skillsColumn = "技術需求"
        static let deadlineColumn = "截止時間"
        static let essentialLocationColumn = "合作地點"
        static let descriptionSectionTitle = "About"
        static let contactSectionTitle = "聯絡人"
        static let applicantsSectionTitle = "應徵者"
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

    struct Portfolio {
        static let sectionHeader = "Portfolio"
    }

    struct Edit {
        static let editIntroduction = "請填寫個人簡介"
        static let editSkills = "Edit Skills"
        static let editInterests = "Edit Interests"
        static let addPortfolio = "Add New Work to Portfolio"
    }

    struct Alert {
        static let longDurationProcess = "處理中，請勿關閉畫面"
    }
}
