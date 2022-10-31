//
//  SelectionCategoriesViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit
import TTGTags

class SelectionCategoriesViewController: UIViewController {
    let tagView = TTGTextTagCollectionView()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
    }

    func layoutViews() {
        view.addSubview(tagView)
        tagView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tagView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            tagView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tagView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        tagView.alignment = .left
        let style = TTGTextTagStyle()
        style.backgroundColor = .yellow
        style.cornerRadius = 10
        let tagTitles = ["Software", "Social Networking", "Workshop", "Music"].map {
            TTGTextTag(content: TTGTextTagStringContent(text: $0), style: style)
        }
        tagView.add(tagTitles)
        tagView.reload()
    }
}
