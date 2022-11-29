//
//  FriendsListViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/7.
//

import UIKit

class UsersListViewController: BaseViewController {
    enum UsageType {
        case friend
        case blockList
    }

    let firebaseManager = FirebaseManager.shared
    var users = [JUser]()
    lazy var filteredUsers = [JUser]() {
        didSet {
            if tableView != nil {
                tableView.reloadData()
            }
        }
    }
    var usageType: UsageType = .friend

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
        tableView.addRefreshHeader { [weak self] in
            self?.updateData()
        }
        tableView.beginHeaderRefreshing()
        layoutViews()
    }

    func updateData() {
        switch usageType {
        case .friend:
            firebaseManager.firebaseQueue.async { [weak self] in
                guard let self = self else { return }
                let group = DispatchGroup()
                var shouldContinue = true

                group.enter()
                self.firebaseManager.getAllFriendsInfo { result in
                    switch result {
                    case .success(let friends):
                        self.users = friends
                        group.leave()
                    case .failure(let error):
                        shouldContinue = false
                        group.leave()
                        group.notify(queue: .main) {
                            self.tableView.endHeaderRefreshing()
                            JProgressHUD.shared.showFailure(text: error.localizedDescription, view: self.view)
                        }
                    }
                }

                group.wait()
                guard shouldContinue else { return }
                group.enter()
                self.firebaseManager.getBlockList { result in
                    switch result {
                    case .success(let blockList):
                        self.users = self.users.filter { user in
                            !blockList.contains(user.id)
                        }
                        self.filteredUsers = self.users
                        group.leave()
                        group.notify(queue: .main) {
                            self.tableView.reloadData()
                            self.tableView.endHeaderRefreshing()
                        }
                    case .failure(let err):
                        shouldContinue = false
                        group.leave()
                        group.notify(queue: .main) {
                            self.tableView.endHeaderRefreshing()
                            JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                        }
                    }
                }
            }
        case .blockList:
            var blockList = [UserID]()

            firebaseManager.firebaseQueue.async { [weak self] in
                guard let self = self else { return }

                let group = DispatchGroup()
                var shouldContinue = true

                group.enter()
                self.firebaseManager.getBlockList { result in
                    switch result {
                    case .success(let list):
                        blockList = list
                        group.leave()
                    case.failure(let err):
                        shouldContinue = false
                        group.leave()
                        print(err)
                        JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                    }
                }

                group.wait()
                guard shouldContinue && !blockList.isEmpty else {
                    self.tableView.endHeaderRefreshing()
                    return
                }
                group.enter()
                self.firebaseManager.getAllMatchedUsersDetail(usersID: blockList) { result in
                    switch result {
                    case .success(let blockedUsers):
                        self.users = blockedUsers
                        self.filteredUsers = blockedUsers
                        self.tableView.endHeaderRefreshing()
                        group.leave()
                        group.notify(queue: .main) {}
                    case .failure(let err):
                        print(err)
                        group.notify(queue: .main) {
                            JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                        }
                    }
                }
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
extension UsersListViewController: UITableViewDelegate {
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
        profileVC.userID = filteredUsers[indexPath.row].id
        if usageType == .blockList {
            profileVC.sourceType = .blockList
        }
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

// MARK: - Table View Datasource
extension UsersListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = filteredUsers[indexPath.row]
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
extension UsersListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredUsers = users.filter { $0.name.localizedStandardContains(searchText) }
        } else {
            filteredUsers = users
        }
        tableView.reloadData()
    }
}
