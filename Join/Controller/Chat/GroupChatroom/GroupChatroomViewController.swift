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

    enum SourceType {
        case chatlist
        case project
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
            tableView.backgroundColor = .Blue4
            tableView.separatorStyle = .none
            tableView.allowsSelection = false
            tableView.contentInset = .init(top: 20, left: 0, bottom: 15, right: 0)
        }
    }

    let firebaseManager = FirebaseManager.shared
    let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? ""
    var sourceType: SourceType = .chatlist
    var chatroomID: ChatroomID?
    var chatroomInfo: GroupChatroom?
    var messages = [Message]()
    var membersInfos = [ChatroomMember]()
    var members = [JUser]()
    var wholeInfoMessages = [WholeInfoMessage]() {
        didSet {
            if tableView != nil && !wholeInfoMessages.isEmpty {
                tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
        listenToNewMessages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavBarAppearance(to: .dark)
        guard chatroomID != nil else { return }
        tabBarController?.tabBar.isHidden = true
        getNecessaryInfo()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateInoutStatus(to: .in)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if sourceType == .chatlist {
            tabBarController?.tabBar.isHidden = false
        }
        updateInoutStatus(to: .out)
    }

    func layoutViews() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3.decrease.circle"),
            style: .plain, target: self, action: #selector(openSettingPage)
        )
    }

    func getNecessaryInfo() {
        JProgressHUD.shared.showLoading(view: self.view)

        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            var shouldContinue = true

            let group = DispatchGroup()
            group.enter()
            guard let chatroomID = self.chatroomID else { return }
            self.firebaseManager.getGroupChatroomInfo(chatroomID: chatroomID) { [unowned self] result in
                switch result {
                case .success(let chatroomInfo):
                    self.chatroomInfo = chatroomInfo
                    self.title = chatroomInfo.name
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                        shouldContinue = false
                    }
                }
            }

            group.wait()
            guard shouldContinue else { return }
            group.enter()
            self.firebaseManager.getAllGroupChatMembersIncludingExit(chatroomID: chatroomID) { result in
                switch result {
                case .success(let membersInfos):
                    self.membersInfos = membersInfos
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                        shouldContinue = false
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
                    group.leave()
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                        shouldContinue = false
                    }
                }
            }

            group.wait()
            guard shouldContinue else { return }
            group.enter()
            guard let chatroomInfo = self.chatroomInfo else { return }
            let membersUserIDs = self.membersInfos.map { $0.userID }
            self.firebaseManager.getAllMatchedUsersDetail(usersID: membersUserIDs) { result in
                switch result {
                case .success(let members):
                    self.members = members
                    group.leave()
                    group.notify(queue: .main) { [unowned self] in
                        var messages = [WholeInfoMessage]()
                        for message in self.messages {
                            if let sender = self.members.first(where: { message.sender == $0.id }) {
                                messages.append(WholeInfoMessage(sender: sender, message: message))
                            } else {
                                print("No such member")
                            }
                        }
                        self.wholeInfoMessages = messages
                        JProgressHUD.shared.dismiss()
                    }
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                    }
                }
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
        guard let groupMembersVC = chatStoryboard.instantiateViewController(
            withIdentifier: GroupMembersViewController.identifier
            ) as? GroupMembersViewController else {
            fatalError("Cannot load group members vc")
        }
        groupMembersVC.chatroomInfo = chatroomInfo
        navigationController?.pushViewController(groupMembersVC, animated: true)
    }

    func updateInoutStatus(to status: InoutStatus) {
        guard chatroomID != nil else { return }
        firebaseManager.updateGroupChatroomInoutStatus(setTo: status, chatroomID: chatroomID!) { result in
            switch result {
            case .success(let status):
                print(status)
            case .failure(let err):
                print(err)
            }
        }
    }
}

// MARK: - Table View Datasource
extension GroupChatroomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wholeInfoMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = wholeInfoMessages[indexPath.row]
        if message.sender.id == myID {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MyMessageCell.identifier, for: indexPath
            ) as? MyMessageCell else {
                fatalError("Cannot create my message cell")
            }
            cell.layoutCell(message: wholeInfoMessages[indexPath.row].message)
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GroupMessageCell.identifier, for: indexPath
            ) as? GroupMessageCell else {
                fatalError("Cannot create message cell")
            }

            cell.layoutCell(message: wholeInfoMessages[indexPath.row])
            cell.tapHandler = { [weak self] in
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                guard let profileVC = personalStoryboard.instantiateViewController(
                    withIdentifier: PersonalProfileViewController.identifier
                ) as? PersonalProfileViewController else {
                    fatalError("Cannot create others profile vc")
                }
                profileVC.userID = self?.wholeInfoMessages[indexPath.row].sender.id
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
            sender: myID,
            type: .text,
            content: message, time: Date()
        )
        saveMessages(message: newMessage)
    }
}
