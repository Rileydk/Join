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
        }
    }

    let firebaseManager = FirebaseManager.shared
    var chatroomInfo: GroupChatroom?
    var shouldReload = true
    lazy var members = [User]() {
        didSet {
            if shouldReload {
                tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let admin = chatroomInfo?.admin else {
            print("No chatroom id")
            return
        }
        if admin == myAccount.id {
            tableView.setEditing(true, animated: true)
            editAction()
        } else {
            addExitButton()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getAllCurrentGroupChatMembers()
    }

    func getAllCurrentGroupChatMembers() {
        guard let chatroomID = chatroomInfo?.id else {
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
                        if let member = members.first(where: { $0.id == myAccount.id }),
                            let index = members.firstIndex(of: member),
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

    func addExitButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
            style: .plain, target: self, action: #selector(exitGroup)
        )
    }

    @objc func exitGroup() {
        alertConfirmExit()
    }

    func alertConfirmExit() {
        guard let chatroom = chatroomInfo else {
            print("No chatroom id")
            return
        }
        let alert = UIAlertController(title: "確定要離開\(chatroom.name)嗎？", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
            self?.leaveGroup()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }

    func leaveGroup() {
        guard let chatroomID = chatroomInfo?.id else {
            print("No chatroom id")
            return
        }
        firebaseManager.updateGroupChatroomMemberStatus(setTo: .exit, membersIDs: [myAccount.id], chatroomID: chatroomID) { [weak self] result in
            switch result {
            case .success:
                ProgressHUD.showSucceed()
                self?.navigationController?.popToRootViewController(animated: true)
            case .failure(let err):
                ProgressHUD.showError()
                print(err)
            }
        }
    }
}

// MARK: - Table View Delegate
extension GroupMembersViewController: UITableViewDelegate {
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
        profileVC.userData = members[indexPath.row - 1]
        navigationController?.pushViewController(profileVC, animated: true)
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
                      let chatroomID = strongSelf.chatroomInfo?.id else { return }
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
            guard let chatroomID = chatroomInfo?.id else {
                print("No chatroom id")
                return
            }
            firebaseManager.updateGroupChatroomMemberStatus(setTo: .exit, membersIDs: [members[indexPath.row - 1].id], chatroomID: chatroomID) { [weak self] result in
                switch result {
                case .success:
                    ProgressHUD.showSucceed()
                    self?.shouldReload = false
                    self?.members.remove(at: indexPath.row - 1)
                    self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self?.shouldReload = true
                case .failure(let err):
                    ProgressHUD.showError()
                    print(err)
                }
            }

        }
    }
}