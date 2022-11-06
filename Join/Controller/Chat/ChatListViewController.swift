//
//  ChatListViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/6.
//

import UIKit

class ChatListViewController: BaseViewController {
    @IBOutlet weak var tabSegmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: ChatListCell.identifier, bundle: nil),
                forCellReuseIdentifier: ChatListCell.identifier
            )
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMessageList()
    }

    func getMessageList() {
        firebaseManager.getAllLatestMessages(type: type) { [unowned self] result in
            switch result {
            case .success(let listItem):
                self.messageList = listItem
            case .failure(let error):
                print(error)
            }
        }
    }
}
