//
//  GroupMembersViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/11.
//

import UIKit

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

    var chatroomID: ChatroomID?
    var members = [User]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

// MARK: - Table View Delegate
extension GroupMembersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
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
}
