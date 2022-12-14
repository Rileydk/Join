//
//  DescriptionCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import UIKit

class ProjectItemCell: TableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .Gray6
    }

    func layoutCellWithPosition(project: Project) {
        iconImageView.image = UIImage(named: JImages.Icon_24px_Person.rawValue)
        itemTitleLabel.text = Constant.FindIdeas.recruitingColumn
        let recruiting = project.recruiting.first!
        contentLabel.text = "\(recruiting.role)  * \(recruiting.number) 人"
    }

    func layoutCellWithSkills(project: Project) {
        iconImageView.image = UIImage(named: JImages.Icon_24px_Tools.rawValue)
        itemTitleLabel.text = Constant.FindIdeas.skillsColumn
        let recruiting = project.recruiting.first!
        contentLabel.text = recruiting.skills
    }

    func layoutCellWithDeadline(project: Project) {
        iconImageView.image = UIImage(named: JImages.Icon_24px_Calendar.rawValue)
        itemTitleLabel.text = Constant.FindIdeas.deadlineColumn
        let deadline = project.deadline!
        contentLabel.text = deadline.formatted
    }

    func layoutCellWithEssentialLocation(project: Project) {
        iconImageView.image = UIImage(named: JImages.Icon_24px_Location.rawValue)
        itemTitleLabel.text = Constant.FindIdeas.essentialLocationColumn
        let location = project.location
        contentLabel.text = location
    }
}
