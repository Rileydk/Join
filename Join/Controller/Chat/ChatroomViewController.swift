//
//  ChatroomViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit

class ChatroomViewController: BaseViewController {
    deinit {
        firebaseManager.detachNewMessageListener()
    }

    @IBOutlet var messageTypingSuperview: MessageTypingSuperview! {
        didSet {
            messageTypingSuperview.delegate = self
        }
    }
    @IBOutlet var tableView: UITableView! {
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
            tableView.backgroundColor = .Blue4
            tableView.separatorStyle = .none
            tableView.allowsSelection = false
            tableView.contentInset = .init(top: 20, left: 0, bottom: 15, right: 0)
        }
    }

    let firebaseManager = FirebaseManager.shared
    let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? ""
    var chatroomID: ChatroomID?
    var messages = [Message]() {
        didSet {
            tableView.reloadData()
        }
    }
    var userData: JUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = userData?.name
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavBarAppearance(to: .dark)
        guard chatroomID != nil else { return }
        updateInoutStatus(to: .in)
        updateData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateInoutStatus(to: .out)
    }

    func updateData() {
        guard let chatroomID = chatroomID, let chattingObject = userData else { return }
        let group = DispatchGroup()

        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            group.enter()
            self.firebaseManager.getUserInfo(id: chattingObject.id) { [weak self] result in
                switch result {
                case .success(let user):
                    self?.userData = user
                case .failure(let error):
                    print(error)
                }
                group.leave()
            }

            group.wait()
            self.firebaseManager.listenToNewMessages(chatroomID: chatroomID) { result in
                switch result {
                case .success(let messages):
                    group.notify(queue: .main) { [weak self] in
                        self?.messages += messages
                    }
                case .failure(let error):
                    group.notify(queue: .main) { [weak self] in
                        print(error)
                    }
                }
            }
        }
    }

    func saveMessages(message: Message) {
        guard let chatroomID = chatroomID else { return }
        firebaseManager.addNewMessage(message: message, chatroomID: chatroomID) { result in
            switch result {
            case .success:
                print("success")
            case .failure(let error):
                print(error)
            }
        }
    }

    func updateInoutStatus(to status: InoutStatus) {
        guard chatroomID != nil else { return }
        firebaseManager.updatePrivateChatInoutStatus(setTo: status, chatroomID: chatroomID!) { result in
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
extension ChatroomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        if message.sender == myID {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MyMessageCell.identifier, for: indexPath
                ) as? MyMessageCell else {
                fatalError("Cannot create my message cell")
            }
            cell.layoutCell(message: message)
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MessageCell.identifier, for: indexPath
                ) as? MessageCell else {
                fatalError("Cannot create message cell")
            }
            cell.layoutCell(imageURL: userData?.thumbnailURL, message: message)
            cell.tapHandler = { [weak self] in
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                guard let profileVC = personalStoryboard.instantiateViewController(
                    withIdentifier: PersonalProfileViewController.identifier
                ) as? PersonalProfileViewController else {
                    fatalError("Cannot create others profile vc")
                }
                profileVC.userID = self?.userData?.id
                profileVC.sourceType = .chatroom
                self?.present(profileVC, animated: true)
            }
            return cell
        }
    }
}

// MARK: - Message Superview Delegate
extension ChatroomViewController: MessageSuperviewDelegate {
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
