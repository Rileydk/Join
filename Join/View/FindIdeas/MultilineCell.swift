//
//  MultilineCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import UIKit

class MultilineCell: TableViewCell {
    @IBOutlet weak var multilineLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func layoutCell(project: Project) {
        multilineLabel.text = project.description
    }
    
}
