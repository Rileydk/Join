//
//  FriendsListViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/7.
//

import UIKit

class FriendsListViewController: BaseViewController {
    let firebaseManager = FirebaseManager.shared
    var friends = [User]()
    lazy var filteredFriends = [User]()

    var searchController = UISearchController()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firebaseManager.getAllFriendsInfo { [unowned self] result in
            switch result {
            case .success(let friends):
                self.friends = friends
                self.filteredFriends = friends
                tableView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
    }

    func layoutViews() {
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

// MARK: - Table View Delegate
extension FriendsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
        guard let profileVC = personalStoryboard.instantiateViewController(
            withIdentifier: OthersProfileViewController.identifier
        ) as? OthersProfileViewController else {
            fatalError("Cannot create others profile vc")
        }
        profileVC.userData = filteredFriends[indexPath.row]
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

// MARK: - Table View Datasource
extension FriendsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredFriends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = filteredFriends[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FriendCell.identifier, for: indexPath
            ) as? FriendCell else {
            fatalError("Cannot create friend cell")
        }
        cell.layoutCell(friend: friend)
        return cell
    }
}

// MARK: - Search Result Updating
extension FriendsListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredFriends = friends.filter { $0.name.localizedStandardContains(searchText) }
        } else {
            filteredFriends = friends
        }
        tableView.reloadData()
    }
}
