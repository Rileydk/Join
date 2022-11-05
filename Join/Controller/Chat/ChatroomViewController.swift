//
//  ChatroomViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/5.
//

import UIKit
import SwiftUI

class ChatroomViewController: BaseViewController {
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
    var senderName: String?
    var senderThumbnail: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        if senderName == nil {

        }
        title = senderName
    }

    func getSenderName(completion: @escaping (Result<String, Error>) -> Void) {

    }

    func updateMessages() {

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
            cell.layoutCell(image: senderThumbnail, message: message.content)
            return cell
        }
    }
}
