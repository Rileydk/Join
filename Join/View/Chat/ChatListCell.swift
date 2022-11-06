//
//  ChatListCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/6.
//

import UIKit

class ChatListCell: TableViewCell {

    @IBOutlet weak var userThumbnail: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var latestMessageLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
