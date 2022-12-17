//
//  RecruitingTitleCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import UIKit

class ProjectTitleCell: TableViewCell {
    enum Action {
        case save
        case remove
    }

    @IBOutlet weak var recruitingTitleLabel: UILabel!
    @IBOutlet weak var savingButton: UIButton!

    var project: Project?
    var saveHandler: ((Action, Project) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .Gray6
    }

    func layoutCell(project: Project) {
        recruitingTitleLabel.text = project.name

        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else { return }
        if myID == project.contact {
            savingButton.isHidden = true
        } else {
            self.project = project
            savingButton.isHidden = false
            savingButton.tintColor = .Yellow1
            let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .large)
            savingButton.setImage(UIImage(
                systemName: "bookmark",
                withConfiguration: largeConfig), for: .normal)
            savingButton.setImage(UIImage(
                systemName: "bookmark.fill",
                withConfiguration: largeConfig), for: .selected)
            if let collectors = project.collectors, collectors.contains(myID) {
                savingButton.isSelected = true
            } else {
                savingButton.isSelected = false
            }
        }
    }
    @IBAction func saveToCollection(_ sender: Any) {
        guard let project = project else { return }
        print("isSelected", savingButton.isSelected)
        if savingButton.isSelected {
            saveHandler?(.save, project)
        } else {
            saveHandler?(.remove, project)
        }
    }
}
