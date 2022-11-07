//
//  FriendsListViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/7.
//

import UIKit

class FriendsListViewController: UIViewController {
    let firebaseManager = FirebaseManager.shared
    var friends = [User]()

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: FriendCell.identifier, bundle: nil),
                forCellReuseIdentifier: FriendCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
        }
    }
}

// MARK: - Table View Delegate
extension FriendsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

// MARK: - Table View Datasource
extension FriendsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = friends[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FriendCell.identifier, for: indexPath
            ) as? FriendCell else {
            fatalError("Cannot create friend cell")
        }
        cell.layoutCell(friend: friend)
        return cell
    }
}
