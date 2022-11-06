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
        firebaseManager.getAllLatestMessages(type: type) { [unowned self] result in
            switch result {
            case .success(let listItem):
                self.messageList = listItem
            case .failure(let error):
                print(error)
            }
        }
    }

    @IBAction func changeTab(_ sender: UISegmentedControl) {
        type = ChatroomType.allCases[sender.selectedSegmentIndex]
    }
}

// MARK: - Table View Delegate
extension ChatListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tapped")
    }
}

// MARK: - Table View Datasource
extension ChatListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messageList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatListCell.identifier,
            for: indexPath) as? ChatListCell else {
            fatalError("Cannot create chat list cell")
        }
        cell.layoutCell(messageItem: messageList[indexPath.row])
        return cell
    }
}
