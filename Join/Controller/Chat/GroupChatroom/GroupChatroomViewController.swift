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
                UINib(nibName: MessageCell.identifier, bundle: nil),
                forCellReuseIdentifier: MessageCell.identifier
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
    var messages = [Message]() {
        didSet {
            tableView.reloadData()
        }
    }
    var members = [User]()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let chatroomID = chatroomID else { return }
        firebaseManager.listenToNewGroupMessages(chatroomID: chatroomID) { [weak self] result in
            switch result {
            case .success(let messages):
                self?.messages += messages
            case .failure(let error):
                print(error)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true

        guard let chatroomID = chatroomID else { return }
        updateAllMessages(chatroomID: chatroomID)
        getChatroominfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    func getChatroominfo() {
        guard let chatroomID = chatroomID else { return }
        firebaseManager.getGroupChatroomInfo(chatroomID: chatroomID) { [unowned self] result in
            switch result {
            case .success(let chatroomInfo):
                self.chatroomInfo = chatroomInfo
                self.firebaseManager.getAllMatchedUsersDetail(usersID: chatroomInfo.members) { result in
                    switch result {
                    case .success(let members):
                        self.members = members
                    case .failure(let err):
                        print(err)
                    }
                }
                self.title = chatroomInfo.name
            case .failure(let err):
                print(err)
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

    func updateAllMessages(chatroomID: ChatroomID) {
        firebaseManager.getAllMessages(chatroomID: chatroomID) { [unowned self] result in
            switch result {
            case .success(let messages):
                self.messages = messages
            case .failure(let error):
                print(error)
            }
        }
    }
}

// MARK: - Table View Datasource
extension GroupChatroomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        if message.sender == myAccount.id {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MyMessageCell.identifier, for: indexPath
            ) as? MyMessageCell else {
                fatalError("Cannot create my message cell")
            }
            cell.layoutCell(message: message.content)
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MessageCell.identifier, for: indexPath
            ) as? MessageCell else {
                fatalError("Cannot create message cell")
            }

            let member = members[indexPath.row]
            cell.layoutCell(imageURL: member.thumbnailURL, message: message.content)
            cell.tapHandler = { [weak self] in
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                guard let profileVC = personalStoryboard.instantiateViewController(
                    withIdentifier: OthersProfileViewController.identifier
                ) as? OthersProfileViewController else {
                    fatalError("Cannot create others profile vc")
                }
                profileVC.userData = member
                self?.navigationController?.pushViewController(profileVC, animated: true)
            }
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
