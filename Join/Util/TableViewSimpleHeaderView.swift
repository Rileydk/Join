//
//  TableViewSimpleHeaderView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/21.
//

import UIKit

class TableViewSimpleHeaderView: TableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutViews()
    }

    func layoutViews() {
        contentView.backgroundColor = .White
        titleLabel.text = Constant.Portfolio.sectionHeader
        titleLabel.textColor = .Blue1
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
