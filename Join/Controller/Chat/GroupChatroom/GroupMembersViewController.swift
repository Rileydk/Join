//
//  GroupMembersViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/11.
//

import UIKit
import ProgressHUD

class GroupMembersViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: FriendCell.identifier, bundle: nil),
                forCellReuseIdentifier: FriendCell.identifier
            )
            tableView.register(
                UINib(nibName: AddNewMemberCell.identifier, bundle: nil),
                forCellReuseIdentifier: AddNewMemberCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.setEditing(true, animated: true)
        }
    }

    let firebaseManager = FirebaseManager.shared
    var chatroomID: ChatroomID?
    lazy var members = [User]() {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        editAction()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getAllCurrentGroupChatMembers()
    }

    func getAllCurrentGroupChatMembers() {
        guard let chatroomID = chatroomID else {
            print("No chatroom id")
            return
        }
        var currentMembersIDs = [UserID]()

        firebaseManager.firebaseQueue.async { [weak self] in
            let group = DispatchGroup()
            group.enter()
            self?.firebaseManager.getAllCurrentGroupChatMembers(chatroomID: chatroomID) { result in
                switch result {
                case .success(let membersIDs):
                    currentMembersIDs = membersIDs
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        print(err)
                    }
                }
            }

            group.wait()
            group.enter()
            self?.firebaseManager.getAllMatchedUsersDetail(usersID: currentMembersIDs) { result in
                switch result {
                case .success(let members):
                    group.leave()
                    group.notify(queue: .main) {
                        var members = members
                        if let index = members.firstIndex(of: myAccount),
                           index != 0 {
                            members.swapAt(0, index)
                        }
                        self?.members = members
                    }
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        print(err)
                    }
                }
            }
        }

    }

    @objc func editAction() {
        tableView.isEditing.toggle()
        if !tableView.isEditing {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .edit, target: self, action: #selector(editAction)
            )
        } else {
            navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editAction))
        }
    }
}

// MARK: - Table View Delegate
extension GroupMembersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        } else if members[indexPath.row - 1].id == myAccount.id {
            return false
        } else {
            return true
        }
    }
}

// MARK: - Table View Datasource
extension GroupMembersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        members.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddNewMemberCell.identifier, for: indexPath
                ) as? AddNewMemberCell else {
                fatalError("Cannot create add new member cell")
            }
            cell.tapHandler = { [weak self] in
                guard let strongSelf = self,
                      let chatroomID = strongSelf.chatroomID else { return }
                let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                guard let friendSelectionVC = chatStoryboard.instantiateViewController(
                    withIdentifier: FriendSelectionViewController.identifier
                ) as? FriendSelectionViewController else {
                    fatalError("Cannot create friend selection vc")
                }
                friendSelectionVC.source = .addNewMembers
                friendSelectionVC.members = strongSelf.members
                friendSelectionVC.chatroomID = chatroomID
                strongSelf.navigationController?.pushViewController(friendSelectionVC, animated: true)
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: FriendCell.identifier, for: indexPath
                ) as? FriendCell else {
                fatalError("Cannot create friend cell")
            }
            cell.layoutCell(friend: members[indexPath.row - 1], source: .friendList)
            return cell
        }
    }

    // swiftlint:disable line_length
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let chatroomID = chatroomID else {
                fatalError("No valid chatroom ID")
            }
            firebaseManager.updateGroupChatroomMemberStatus(setTo: .exit, membersIDs: [members[indexPath.row - 1].id], chatroomID: chatroomID) { [weak self] result in
                switch result {
                case .success:
                    ProgressHUD.showSucceed()
                    self?.members.remove(at: indexPath.row - 1)
                case .failure(let err):
                    ProgressHUD.showError()
                    print(err)
                }
            }

        }
    }
}
