//
//  ChatListViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/6.
//

import UIKit

class ChatListViewController: BaseViewController {
    @IBOutlet weak var tabSegmentedControl: UISegmentedControl!
    @IBOutlet weak var addGroupChatroomBarButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: ChatListCell.identifier, bundle: nil),
                forCellReuseIdentifier: ChatListCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
        }
    }

    let firebaseManager = FirebaseManager.shared
    var type: ChatroomType = .friend {
        didSet {
            guard tableView != nil else { return }
            getMessageList()
        }
    }
    var messageList = [MessageListItem]() {
        didSet {
            tableView.reloadData()
        }
    }
    var groupMessageList = [GroupMessageListItem]() {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMessageList()
    }

    func layoutViews() {
        let types = ChatroomType.allCases
        for i in 0 ..< types.count {
            tabSegmentedControl.setTitle(types[i].buttonTitle, forSegmentAt: i)
        }
        tabSegmentedControl.selectedSegmentIndex = types.firstIndex(of: .friend)!
    }

    func getMessageList() {
        if type == .group {
            var chatroomIDsBox = [ChatroomID]()
            var groupMessageListItems = [GroupMessageListItem]()

            firebaseManager.firebaseQueue.async { [weak self] in
                let group = DispatchGroup()
                group.enter()
                self?.firebaseManager.getAllSavedGroupChatroomIDs { result in
                    switch result {
                    case .success(let chatroomIDs):
                        chatroomIDsBox = chatroomIDs
                        group.leave()
                    case .failure(let err):
                        print(err)
                        group.leave()
                    }
                }

                group.wait()
                group.enter()
                self?.firebaseManager.getAllLatestGroupMessages(chatroomIDs: chatroomIDsBox) { result in
                    switch result {
                    case .success(let groupListItems):
                        groupMessageListItems = groupListItems
                        group.leave()
                    case .failure(let err):
                        print(err)
                        group.leave()
                    }
                }

                group.wait()
                group.enter()
                self?.firebaseManager.getAllGroupChatroomInfo(messagesItems: groupMessageListItems) { result in
                    switch result {
                    case .success(let groupListItems):
                        groupMessageListItems = groupListItems
                        group.leave()
                    case .failure(let err):
                        print(err)
                        group.leave()
                    }
                }

                group.notify(queue: .main) { [weak self] in
                    let groupMessageListItems = groupMessageListItems.filter { $0.chatroom != nil }
                    self?.groupMessageList = groupMessageListItems
                }
            }

        } else {
            firebaseManager.getAllLatestMessages(type: type) { [unowned self] result in
                switch result {
                case .success(let listItem):
                    self.messageList = listItem
                case .failure(let error):
                    self.messageList = []
                    print(error)
                }
            }
        }
    }

    @IBAction func changeTab(_ sender: UISegmentedControl) {
        type = ChatroomType.allCases[sender.selectedSegmentIndex]
    }
    @IBAction func addGroupChatroom(_ sender: UIBarButtonItem) {
        let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
        guard let friendSelectionVC = chatStoryboard.instantiateViewController(
            withIdentifier: FriendSelectionViewController.identifier
            ) as? FriendSelectionViewController else {
            fatalError("Cannot create friend selection vc")
        }
        navigationController?.pushViewController(friendSelectionVC, animated: true)
    }
}

// MARK: - Table View Delegate
extension ChatListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if type == .group {
            let chatroomID = groupMessageList[indexPath.row].chatroomID
            let chatroomName = groupMessageList[indexPath.row].chatroom!.name
            let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
            guard let chatroomVC =  chatStoryboard.instantiateViewController(
                withIdentifier: GroupChatroomViewController.identifier
            ) as? GroupChatroomViewController else {
                fatalError("Cannot get chatroom vc")
            }
            chatroomVC.chatroomID = chatroomID
            chatroomVC.title = chatroomName

            navigationController?.pushViewController(chatroomVC, animated: true)

        } else {
            let userID = messageList[indexPath.row].userID
            let chatroomID = messageList[indexPath.row].chatroomID

            firebaseManager.getUserInfo(id: userID) { result in
                switch result {
                case .success(let user):
                    let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                    guard let chatVC = chatStoryboard.instantiateViewController(
                        withIdentifier: ChatroomViewController.identifier
                    ) as? ChatroomViewController else {
                        fatalError("Cannot create chatroom vc")
                    }

                    chatVC.userData = user
                    chatVC.chatroomID = chatroomID
                    self.hidesBottomBarWhenPushed = true
                    DispatchQueue.main.async { [unowned self] in
                        self.hidesBottomBarWhenPushed = false
                    }
                    self.navigationController?.pushViewController(chatVC, animated: true)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}

// MARK: - Table View Datasource
extension ChatListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if type == .group {
            return groupMessageList.count
        } else {
            return messageList.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatListCell.identifier,
            for: indexPath) as? ChatListCell else {
            fatalError("Cannot create chat list cell")
        }
        if type == .group {
            cell.layoutCell(groupMessageItem: groupMessageList[indexPath.row])
        } else {
            cell.layoutCell(messageItem: messageList[indexPath.row])
            return cell
        }

        return cell
    }
}
