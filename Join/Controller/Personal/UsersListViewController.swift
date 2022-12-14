//
//  FriendsListViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/7.
//

import UIKit

struct FriendItem {
    enum FriendItemType {
        case friend
        case friendRequest
    }

    let userInfo: JUser
    let type: FriendItemType
}

class UsersListViewController: BaseViewController {
    enum UsageType {
        case friend
        case blockList
    }

    let firebaseManager = FirebaseManager.shared
    let userManager = UserManager.shared
    var users = [FriendItem]()
    lazy var filteredUsers = [FriendItem]() {
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
            tableView.register(
                UINib(nibName: ContactCell.identifier, bundle: nil),
                forCellReuseIdentifier: ContactCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.backgroundColor = .Gray6
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let backIcon = UIImage(named: JImages.Icon_24px_Back.rawValue)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: backIcon,
            style: .plain, target: self, action: #selector(backToPreviousPage))

        tableView.addRefreshHeader { [weak self] in
            self?.updateData()
        }
        switch usageType {
        case .friend:
            title = Constant.Personal.myFriends
        case .blockList:
            title = Constant.Personal.myBlockList
        }
        tableView.beginHeaderRefreshing()
        layoutViews()
    }

    func updateData() {
        users = []
        switch usageType {
        case .friend:
            firebaseManager.firebaseQueue.async { [weak self] in
                guard let self = self, let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else { return }
                var receivedRequest: [UserID]?

                let group = DispatchGroup()
                var shouldContinue = true

                group.enter()
                self.userManager.getSingleUserData(userID: myID) { myUserData in
                    receivedRequest = myUserData?.receivedRequests
                    group.leave()
                }

                group.wait()
                group.enter()
                if let receivedRequest = receivedRequest, !receivedRequest.isEmpty {
                    self.firebaseManager.getAllMatchedUsersDetail(usersID: receivedRequest) { result in
                        switch result {
                        case .success(let inviters):
                            self.users = inviters.map {
                                FriendItem(userInfo: $0, type: .friendRequest)
                            }
                        case .failure(let error):
                            print(error)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }

                group.wait()
                group.enter()
                self.firebaseManager.getAllFriendsInfo { result in
                    switch result {
                    case .success(let friends):
                        self.users += friends.map {
                            FriendItem(userInfo: $0, type: .friend)
                        }
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
                        self.users = self.users.filter { userItem in
                            !blockList.contains(userItem.userInfo.id)
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
                        self.users = blockedUsers.map {
                            FriendItem(userInfo: $0, type: .friend)
                        }
                        self.filteredUsers = self.users
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

    func acceptFriendRequest(userID: UserID?) {
        JProgressHUD.shared.showLoading(text: Constant.Personal.sending, view: view)
        guard let userID = userID else { return }
        userManager.acceptFriendRequest(from: userID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.updateData()
                JProgressHUD.shared.showSuccess(view: self.view)
            case .failure(let error):
                print(error)
                JProgressHUD.shared.showFailure(view: self.view)
            }
        }
    }

    @objc func backToPreviousPage() {
        navigationController?.popViewController(animated: true)
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
        profileVC.userID = filteredUsers[indexPath.row].userInfo.id
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
        let user = filteredUsers[indexPath.row]
        switch user.type {
        case .friend:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: FriendCell.identifier, for: indexPath
                ) as? FriendCell else {
                fatalError("Cannot create friend cell")
            }
            cell.layoutCell(friend: user.userInfo, source: .friendList)
            return cell

        case .friendRequest:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactCell.identifier, for: indexPath
                ) as? ContactCell else {
                fatalError("Cannot create contact cell")
            }
            cell.layoutCell(user: user, from: .receivedRequest)
            cell.acceptFriendRequestHandler = { [weak self] inviter in
                self?.acceptFriendRequest(userID: inviter.userInfo.id)
            }
            return cell
        }
    }
}

// MARK: - Search Result Updating
extension UsersListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredUsers = users.filter { $0.userInfo.name.localizedStandardContains(searchText) }
        } else {
            filteredUsers = users
        }
        tableView.reloadData()
    }
}
