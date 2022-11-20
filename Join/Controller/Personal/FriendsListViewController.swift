//
//  FriendsListViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/7.
//

import UIKit

class FriendsListViewController: BaseViewController {
    let firebaseManager = FirebaseManager.shared
    var friends = [JUser]()
    lazy var filteredFriends = [JUser]()

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
            tableView.backgroundColor = .Gray6
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        JProgressHUD.shared.showLoading(view: self.view)
        firebaseManager.getAllFriendsInfo { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let friends):
                self.friends = friends
                self.filteredFriends = friends
                self.tableView.reloadData()
                JProgressHUD.shared.dismiss()
            case .failure(let error):
                JProgressHUD.shared.showFailure(text: error.localizedDescription, view: self.view)
            }
        }
    }

    func layoutViews() {
        view.backgroundColor = .Gray6

        searchController.searchBar.searchTextField.backgroundColor = .White
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
            withIdentifier: PersonalProfileViewController.identifier
        ) as? PersonalProfileViewController else {
            fatalError("Cannot create others profile vc")
        }
        profileVC.userID = filteredFriends[indexPath.row].id
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
        cell.layoutCell(friend: friend, source: .friendList)
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
