//
//  AddNewMemberCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/11.
//

import UIKit

class AddNewMemberCell: TableViewCell {
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func addNewMembers(_ sender: UIButton) {
    }
}
