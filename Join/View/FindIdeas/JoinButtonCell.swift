//
//  JoinButtonCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class JoinButtonCell: TableViewCell {
    enum UsageType: String {
        case joinProject = "Join"
        case createProjectGroup = "建立工作群組"
        case goToProjectGroup = "進入工作群組"

        var backgroundColor: UIColor {
            switch self {
            case .joinProject, .createProjectGroup: return .Blue1 ?? .black
            case .goToProjectGroup: return .Yellow1 ?? .white
            }
        }

        var titleColor: UIColor {
            switch self {
            case .joinProject, .createProjectGroup: return .White ?? .white
            case .goToProjectGroup: return .Gray1 ?? .black
            }
        }
    }

    @IBOutlet weak var joinButton: UIButton!
    var tapHandler: ((UsageType) -> Void)?
    var usageType: UsageType = .joinProject

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func layoutCell(type: UsageType) {
        joinButton.setTitle(type.rawValue, for: .normal)
        joinButton.setTitleColor(type.titleColor, for: .normal)
        joinButton.backgroundColor = type.backgroundColor
        usageType = type
    }

    @IBAction func joinProject() {
        tapHandler?(usageType)
    }

}
