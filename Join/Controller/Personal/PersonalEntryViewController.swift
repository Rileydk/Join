//
//  PersonalMainViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class PersonalEntryViewController: UIViewController {
    enum Section: CaseIterable {
        case person
        case goNextPage
    }

    enum NextPage: String, CaseIterable {
        case profile = "個人頁面"
        case friends = "我的好友"
        case preference = "偏好設定"
    }

    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: PersonalMainThumbnailCell.identifier, bundle: nil),
                forCellReuseIdentifier: PersonalMainThumbnailCell.identifier
            )
            tableView.register(
                UINib(nibName: GoNextPageButtonCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoNextPageButtonCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
}

// MARK: - Table View Delegate
extension PersonalEntryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 250
        } else {
            return 60
        }
    }
}

// MARK: - Table View Datasource
extension PersonalEntryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Section.allCases[section] == .goNextPage {
            return NextPage.allCases.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PersonalMainThumbnailCell.identifier,
                for: indexPath) as? PersonalMainThumbnailCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.layoutCell(user: myAccount)
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GoNextPageButtonCell.identifier,
                for: indexPath) as? GoNextPageButtonCell else {
                fatalError("Cannot create go next page button cell")
            }
            cell.layoutCell(title: NextPage.allCases[indexPath.row].rawValue)
            return cell
        }
    }
}
