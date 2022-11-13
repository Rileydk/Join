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
            tableView.backgroundColor = .yellow
            tableView.separatorStyle = .none
            tableView.allowsSelection = false
        }
    }

    let firebaseManager = FirebaseManager.shared
    var chatroomID: ChatroomID?
    var messages = [Message]() {
        didSet {
            tableView.reloadData()
        }
    }
    var userData: User? {
        didSet {
            firebaseManager.downloadImage(urlString: userData!.thumbnailURL) { [unowned self] result in
                switch result {
                case .success(let image):
                    self.userThumbnail = image
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    var userThumbnail: UIImage? {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = userData?.name

        guard let chatroomID = chatroomID else { return }
        firebaseManager.listenToNewMessages(chatroomID: chatroomID) { [weak self] result in
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

        updateUserData()
        guard let chatroomID = chatroomID else { return }
        updateMessages(chatroomID: chatroomID)
        updateInoutStatus(to: .in)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        updateInoutStatus(to: .out)
    }

    func updateUserData() {
        guard let chattingObject = userData else { return }
        firebaseManager.getUserInfo(id: chattingObject.id) { [unowned self] result in
            switch result {
            case .success(let user):
                self.userData = user
            case .failure(let error):
                print(error)
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

    func updateMessages(chatroomID: ChatroomID) {
        firebaseManager.getMessages(of: chatroomID) { [unowned self] result in
            switch result {
            case .success(let messages):
                self.messages = messages
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
            cell.layoutCell(imageURL: userData?.thumbnailURL, message: message.content)
            cell.tapHandler = { [weak self] in
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                guard let profileVC = personalStoryboard.instantiateViewController(
                    withIdentifier: OthersProfileViewController.identifier
                ) as? OthersProfileViewController else {
                    fatalError("Cannot create others profile vc")
                }
                profileVC.userData = self?.userData
                self?.navigationController?.pushViewController(profileVC, animated: true)
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
            sender: myAccount.id,
            type: .text,
            content: message, time: Date()
        )
        saveMessages(message: newMessage)
    }
}
