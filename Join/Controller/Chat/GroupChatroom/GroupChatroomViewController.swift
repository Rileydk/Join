//
//  GroupChatroomViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/10.
//

import UIKit

class GroupChatroomViewController: BaseViewController {
    deinit {
        firebaseManager.detachNewMessageListener()
    }

    @IBOutlet weak var messageTypingSuperview: MessageTypingSuperview! {
        didSet {
            messageTypingSuperview.delegate = self
        }
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: MyMessageCell.identifier, bundle: nil),
                forCellReuseIdentifier: MyMessageCell.identifier
            )
            tableView.register(
                UINib(nibName: GroupMessageCell.identifier, bundle: nil),
                forCellReuseIdentifier: GroupMessageCell.identifier
            )
            tableView.dataSource = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 60
            tableView.backgroundColor = .yellow
            tableView.separatorStyle = .none
            tableView.allowsSelection = false
        }
    }

    let firebaseManager = FirebaseManager.shared
    var chatroomID: ChatroomID?
    var chatroomInfo: GroupChatroom?
    var messages = [Message]()
    var members = [User]()
    var wholeInfoMessages = [WholeInfoMessage]() {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
        listenToNewMessages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true

        guard chatroomID != nil else { return }
        getNeccesaryInfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    func layoutViews() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3.decrease.circle"),
            style: .plain, target: self, action: #selector(openSettingPage)
        )
    }

    func getNeccesaryInfo() {
        firebaseManager.firebaseQueue.async { [unowned self] in
            let group = DispatchGroup()
            group.enter()
            guard let chatroomID = self.chatroomID else { return }
            firebaseManager.getGroupChatroomInfo(chatroomID: chatroomID) { [unowned self] result in
                switch result {
                case .success(let chatroomInfo):
                    self.chatroomInfo = chatroomInfo
                    self.title = chatroomInfo.name
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        print(err)
                    }
                }
            }

            group.enter()
            self.firebaseManager.getGroupMessages(of: chatroomID) { [unowned self] result in
                switch result {
                case .success(let messages):
                    self.messages = messages
                    group.leave()
                case .failure(let err):
                    group.notify(queue: .main) {
                        print(err)
                    }
                }
            }

            group.wait()
            group.enter()
            guard let chatroomInfo = self.chatroomInfo else { return }
            let membersIDs = chatroomInfo.members.map { $0.id }
            self.firebaseManager.getAllMatchedUsersDetail(usersID: membersIDs) { result in
                switch result {
                case .success(let members):
                    self.members = members
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        print(err)
                    }
                }
            }

            group.notify(queue: .main) { [unowned self] in
                var messages = [WholeInfoMessage]()
                for message in self.messages {
                    if let sender = self.members.first(where: { message.sender == $0.id }) {
                        messages.append(WholeInfoMessage(sender: sender, message: message))
                    } else {
                        print("No such member")
                    }
                }
                wholeInfoMessages = messages
            }
        }
    }

    func saveMessages(message: Message) {
        guard let chatroomID = chatroomID else { return }
        firebaseManager.addNewGroupMessage(message: message, chatroomID: chatroomID) { result in
            switch result {
            case .success:
                print("success")
            case .failure(let error):
                print(error)
            }
        }
    }

    func listenToNewMessages() {
        guard let chatroomID = chatroomID else { return }
        firebaseManager.listenToNewGroupMessages(chatroomID: chatroomID) { [unowned self] result in
            switch result {
            case .success(let newMessages):
                self.messages += newMessages
                var messages = [WholeInfoMessage]()
                for message in newMessages {
                    if let sender = self.members.first(where: { message.sender == $0.id }) {
                        messages.append(WholeInfoMessage(sender: sender, message: message))
                    } else {
                        print("No such member")
                    }
                }
                wholeInfoMessages += messages
            case .failure(let error):
                print(error)
            }
        }
    }

    @objc func openSettingPage() {
        guard let chatroomID = chatroomID else { return }
        let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
        guard let groupMembersVC = chatStoryboard.instantiateViewController(withIdentifier: GroupMembersViewController.identifier) as? GroupMembersViewController else {
            fatalError("Cannot load group members vc")
        }
        groupMembersVC.members = members
        groupMembersVC.chatroomID = chatroomID
        navigationController?.pushViewController(groupMembersVC, animated: true)
    }
}

// MARK: - Table View Datasource
extension GroupChatroomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wholeInfoMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        if message.sender == myAccount.id {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MyMessageCell.identifier, for: indexPath
            ) as? MyMessageCell else {
                fatalError("Cannot create my message cell")
            }
            cell.layoutCell(message: wholeInfoMessages[indexPath.row].message.content)
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GroupMessageCell.identifier, for: indexPath
            ) as? GroupMessageCell else {
                fatalError("Cannot create message cell")
            }

            cell.layoutCell(message: wholeInfoMessages[indexPath.row])
//            cell.tapHandler = { [weak self] in
//                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
//                guard let profileVC = personalStoryboard.instantiateViewController(
//                    withIdentifier: OthersProfileViewController.identifier
//                ) as? OthersProfileViewController else {
//                    fatalError("Cannot create others profile vc")
//                }
//                profileVC.userData = member
//                self?.navigationController?.pushViewController(profileVC, animated: true)
//            }
            return cell
        }
    }
}

// MARK: - Message Superview Delegate
extension GroupChatroomViewController: MessageSuperviewDelegate {
    func view(_ messageTypingSuperview: MessageTypingSuperview, didSend message: String) {
        let newMessage = Message(
            messageID: "",
            sender: myAccount.id,
            type: .text,
            content: message, time: Date()
        )
        saveMessages(message: newMessage)
    }
}
