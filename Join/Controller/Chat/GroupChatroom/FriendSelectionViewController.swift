//
//  FriendSelectionViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/10.
//

import UIKit

class FriendSelectionViewController: BaseViewController {
    enum Source {
        case createNewGroupChat
        case secondStepWhenCreateNewGroupChat
        case addNewMembers
        case addMembers
    }

    let firebaseManager = FirebaseManager.shared

    var source: Source = .createNewGroupChat
    var friends = [JUser]()
    var members = [JUser]()
    var chatroomID: ChatroomID?
    var filteredFriends = [JUser]()
    var selectedIndexes = [Int]()
    var selectedFriends = [JUser]()
    var addToFindPartnersHandler: (([JUser]) -> Void)?
    var addToMemberSelectionHandler: (([JUser]) -> Void)?

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
            tableView.allowsMultipleSelection = true
            tableView.backgroundColor = .Gray6
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            let group = DispatchGroup()
            var shouldContinue = true

            group.enter()
            self.firebaseManager.getAllFriendsInfo { result in
                switch result {
                case .success(let friends):
                    self.friends = friends
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
                    self.friends = self.friends.filter { friend in
                        !blockList.contains(friend.id)
                    }
                    self.filteredFriends = self.friends
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
    }

    func layoutViews() {
        switch source {
        case .addNewMembers, .createNewGroupChat, .secondStepWhenCreateNewGroupChat:
            title = selectedFriends.isEmpty ? "選擇群組成員" : "已選擇\(selectedFriends.count)個成員"
        case .addMembers:
            title = selectedFriends.isEmpty ? "選擇團隊成員" : "已選擇\(selectedFriends.count)個成員"
        }

        searchController.searchBar.searchTextField.backgroundColor = .White
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        if source == .createNewGroupChat {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Next", style: .done, target: self, action: #selector(prepareGroupChatroom)
            )
        } else if source == .secondStepWhenCreateNewGroupChat {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Invite", style: .done, target: self, action: #selector(addNewMembers)
            )
        } else if source == .addNewMembers {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Invite", style: .done, target: self, action: #selector(addNewMembersToExistedGroupChatroom)
            )
        } else if source == .addMembers {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Add", style: .done, target: self, action: #selector(addNewMembers)
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Add", style: .done, target: self, action: #selector(addNewMembersToExistedGroupChatroom)
            )
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: JImages.Icons_24px_Close.rawValue), style: .plain,
            target: self, action: #selector(backToPreviousPage))
    }

    @objc func prepareGroupChatroom() {
        let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
        guard let groupCreationVC = chatStoryboard.instantiateViewController(
            withIdentifier: GroupCreationViewController.identifier
            ) as? GroupCreationViewController else {
            fatalError("Cannot create group creation vc")
        }
        groupCreationVC.selectedFriends = selectedFriends
        navigationController?.pushViewController(groupCreationVC, animated: true)
    }

    @objc func addNewMembersToExistedGroupChatroom() {
        guard let chatroomID = chatroomID else { return }
        let newMembers = selectedFriends.map {
            ChatroomMember(
                userID: $0.id, currentMemberStatus: .join,
                currentInoutStatus: .out, lastTimeInChatroom: Date()
            )
        }
        // swiftlint:disable line_length
        JProgressHUD.shared.showSaving(view: self.view)
        firebaseManager.addNewGroupChatMembers(chatroomID: chatroomID, selectedMembers: newMembers) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:

                guard let chatroomVC = self.navigationController?.viewControllers
                    .dropLast().dropLast().last! else {
                    fatalError("Cannot go back to chatroom vc")
                }
                JProgressHUD.shared.showSuccess(view: self.view) {
                    self.navigationController?.popToViewController(chatroomVC, animated: true)
                }
            case .failure(let err):
                JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
            }
        }
    }

    @objc func addNewMembers() {
        addToFindPartnersHandler?(selectedFriends)
        addToMemberSelectionHandler?(selectedFriends)
        backToPreviousPage()
    }

    @objc func backToPreviousPage() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Table View Delegate
extension FriendSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? FriendCell else {
            fatalError("Cannot get friend cell")
        }

        if members.contains(filteredFriends[indexPath.row]) { return }

        if let index = selectedFriends.firstIndex(of: filteredFriends[indexPath.row]) {
            selectedFriends.remove(at: index)
            cell.selectImageView.image = UIImage(systemName: "checkmark.circle")
        } else {
            selectedFriends.append(filteredFriends[indexPath.row])
            cell.selectImageView.image = UIImage(systemName: "checkmark.circle.fill")
        }
        title = "已選擇\(selectedFriends.count)個好友"
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - Table View Datasource
extension FriendSelectionViewController: UITableViewDataSource {
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

        let isMember = members.contains(friend)
        cell.layoutCell(
            friend: friend, source: .friendSelection, isMember: isMember,
            isSelectedNow: selectedFriends.contains(filteredFriends[indexPath.row])
        )
        return cell
    }
}

// MARK: - Search Result Updating
extension FriendSelectionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredFriends = friends.filter { $0.name.localizedStandardContains(searchText) }
        } else {
            filteredFriends = friends
        }
        tableView.reloadData()
    }
}
