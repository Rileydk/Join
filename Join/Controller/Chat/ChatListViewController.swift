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
            tableView.backgroundColor = .Gray6
        }
    }

    let firebaseManager = FirebaseManager.shared
    var type: ChatroomType = .friend {
        didSet {
            guard tableView != nil else { return }
            getMessageList()
        }
    }
    // 一對一聊天室用
    var messageList = [MessageListItem]() {
        didSet {
            tableView.reloadData()
        }
    }
    // 群組聊天室用
    var groupMessageList = [GroupMessageListItem]() {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonDisplayMode = .minimal
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMessageList()
        tableView.allowsSelection = true
    }

    func layoutViews() {
        view.backgroundColor = .Gray6

        let types = ChatroomType.allCases
        for index in 0 ..< types.count {
            tabSegmentedControl.setTitle(types[index].buttonTitle, forSegmentAt: index)
        }
        tabSegmentedControl.selectedSegmentIndex = types.firstIndex(of: .friend)!
        addGroupChatroomBarButton.tintColor = .White
    }

    func getMessageList() {
        JProgressHUD.shared.showLoading(view: self.view)

        if type == .group {
            self.groupMessageList = []
            firebaseManager.getAllGroupMessages { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let groupMessagesList):
                    let listItem = groupMessagesList.sorted(by: {
                        ($0.messages.first?.time ?? $0.chatroom.createdTime) >
                        $1.messages.first?.time ?? $0.chatroom.createdTime
                    })
                    self.groupMessageList = listItem
                    JProgressHUD.shared.dismiss()
                case .failure(let err):
                    self.groupMessageList = []
                    if err as? CommonError == .noMessage {
                        JProgressHUD.shared.dismiss()
                    } else {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                    }
                }
            }

        } else {
            self.messageList = []
            firebaseManager.firebaseQueue.async { [weak self] in
                guard let self = self else { return }
                let group = DispatchGroup()
                var shouldContinue = true
                var rawMessageList = [MessageListItem]()

                group.enter()
                self.firebaseManager.getAllMessagesCombinedWithSender(type: self.type) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let listItem):
                        rawMessageList = listItem
                        group.leave()
                    case .failure(let err):
                        self.messageList = []
                        if err as? CommonError == .noMessage {
                            JProgressHUD.shared.dismiss()
                        } else {
                            JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                        }
                    }
                }

                group.wait()
                guard shouldContinue else { return }
                group.enter()
                self.firebaseManager.getBlockList { result in
                    switch result {
                    case .success(let blockList):
                        rawMessageList = rawMessageList.filter { messageItem in
                            return !blockList.contains(messageItem.objectID)
                        }
                        rawMessageList = rawMessageList.sorted(by: {
                            $0.messages.first!.time > $1.messages.first!.time
                        })
                        self.messageList = rawMessageList
                        group.leave()
                        group.notify(queue: .main) {
                            JProgressHUD.shared.dismiss()
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
        tableView.allowsSelection = false

        if type == .group {
            let chatroomID = groupMessageList[indexPath.row].chatroomID
            let chatroomName = groupMessageList[indexPath.row].chatroom.name
            let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
            guard let chatroomVC = chatStoryboard.instantiateViewController(
                withIdentifier: GroupChatroomViewController.identifier
            ) as? GroupChatroomViewController else {
                fatalError("Cannot get chatroom vc")
            }
            chatroomVC.chatroomID = chatroomID
            chatroomVC.title = chatroomName
            hidesBottomBarWhenPushed = true
            DispatchQueue.main.async { [weak self] in
                self?.hidesBottomBarWhenPushed = false
            }
            navigationController?.pushViewController(chatroomVC, animated: true)

        } else {
            let userID = messageList[indexPath.row].objectID
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
