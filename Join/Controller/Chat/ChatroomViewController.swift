//
//  ChatroomViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit

class ChatroomViewController: BaseViewController {
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
        }
    }

    let firebaseManager = FirebaseManager.shared
    var messages: [Message] = [
        Message(sender: yichen.id, type: .text, content: "今晚吃什麼？", time: Date()),
        Message(sender: riley.id, type: .text, content: "不知道耶，你說呢？", time: Date()),
        Message(sender: yichen.id, type: .text, content: "麥當勞", time: Date()),
        Message(sender: riley.id, type: .text, content: "你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎你吃不膩嗎", time: Date()),
        Message(sender: yichen.id, type: .text, content: "哈哈哈哈哈哈哈哈哈哈\n你什麼時候看我吃膩過 😊", time: Date())
    ]
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
    var userThumbnail: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUserData()
        updateMessages()
    }

    func updateUserData() {
        guard let id = userData?.id else { return }
        firebaseManager.getUserInfo(id: id) { [unowned self] result in
            switch result {
            case .success(let user):
                self.userData = user
            case .failure(let error):
                print(error)
            }
        }
    }

    func updateMessages() {
        guard let id = userData?.id else { return }

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
            cell.layoutCell(image: userThumbnail, message: message.content)
            return cell
        }
    }
}

// MARK: - Message Superview Delegate
extension ChatroomViewController: MessageSuperviewDelegate {
    func view(_ messageTypingSuperview: MessageTypingSuperview, didSend message: String) {
        print(message)
    }
}
