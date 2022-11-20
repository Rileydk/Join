//
//  CollectionSimpleHeaderView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/20.
//

import Foundation
import UIKit

class CollectionSimpleHeaderView: UICollectionReusableView {
    let label: UILabel = {
        let label = UILabel()
        label.text = Constant.Portfolio.sectionHeader
        label.textColor = .Blue1
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func layoutViews() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
