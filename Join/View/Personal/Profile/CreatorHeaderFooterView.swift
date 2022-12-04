//
//  CreatorHeaderFooterView.swift
//  Join
//
//  Created by Riley Lai on 2022/12/2.
//

import UIKit

class CreatorHeaderFooterView: TableViewHeaderFooterView {
    @IBOutlet var creatorImageView: UIImageView!
    @IBOutlet var workNameLabel: UILabel!
    @IBOutlet var creatorName: UILabel!

    func layoutView(user: JUser, workItem: WorkItem) {
        creatorImageView.loadImage(user.thumbnailURL)
        workNameLabel.text = workItem.name
        creatorName.text = user.name
    }
}
