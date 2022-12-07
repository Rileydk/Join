//
//  BaseTabBarController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

enum Tab {
    case findIdeas
    case findPartners
    case chat
    case personal

    var title: String {
        switch self {
        case .findIdeas: return "找點子"
        case .findPartners: return "找夥伴"
        case .chat: return "去聊聊"
        case .personal: return "我的專頁"
        }
    }

    func controller() -> UIViewController {
        var controller: UIViewController

        switch self {
        case .findIdeas:
            controller = UIStoryboard.findIdeas.instantiateInitialViewController()!
        case .findPartners:
            controller = UIStoryboard.findPartners.instantiateInitialViewController()!
        case .chat:
            controller = UIStoryboard.chat.instantiateInitialViewController()!
        case .personal:
            controller = UIStoryboard.personal.instantiateInitialViewController()!
        }

        controller.tabBarItem = tabBarItem()

        return controller
    }

    func tabBarItem() -> UITabBarItem {
        switch self {
        case .findIdeas:
            return UITabBarItem(
                title: self.title,
                image: UIImage(systemName: "lightbulb"),
                selectedImage: UIImage(systemName: "lightbulb.fill")
            )
        case .findPartners:
            return UITabBarItem(
                title: self.title,
                image: UIImage(systemName: "person.3"),
                selectedImage: UIImage(systemName: "person.3.fill")
            )
        case .chat:
            return UITabBarItem(
                title: self.title,
                image: UIImage(systemName: "message"),
                selectedImage: UIImage(systemName: "message.fill")
            )
        case .personal:
            return UITabBarItem(
                title: self.title,
                image: UIImage(systemName: "person.circle"),
                selectedImage: UIImage(systemName: "person.circle.fill")
            )
        }
    }
}

class TabBarController: UITabBarController {
    static var identifier: String {
        String(describing: self)
    }
    let firebaseManager = FirebaseManager.shared
    var totalUnreadMessages = 0 {
        didSet {
            guard let chatItem = tabBar.items?[2] else { return }
            chatItem.badgeColor = .Red
            if totalUnreadMessages == 0 {
                chatItem.badgeValue = nil
            } else {
                chatItem.badgeValue = "\(totalUnreadMessages)"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tabs: [Tab] = [.findIdeas, .findPartners, .chat, .personal]
        viewControllers = tabs.map { $0.controller() }
        tabBar.tintColor = .Blue1
//        addListenerToAllChatrooms()
    }

    func updateTotalUnreadMessages() {
        var groupUnread = 0
        var privateUnread = 0
        if let chatItem = tabBar.items?[2] {
            chatItem.badgeValue = nil
        }
        getMessageList { [weak self] allChatrooms in
            groupUnread = allChatrooms.group.map { chatroom in
                chatroom.messages.filter { $0.time > chatroom.lastTimeInChatroom }.count
            }.reduce(0, +)
            privateUnread = allChatrooms.private.map { chatroom in
                chatroom.messages.filter { $0.time > chatroom.lastTimeInChatroom }.count
            }.reduce(0, +)

            self?.totalUnreadMessages = groupUnread + privateUnread
        }
    }

    func addListenerToAllChatrooms() {
        getMessageList { [weak self] allChatrooms in
            guard let self = self else { return }
            let groupChatroomIDs = allChatrooms.group.map { $0.chatroomID }
            let privateChatroomIDs = allChatrooms.private.map { $0.chatroomID }
            groupChatroomIDs.forEach {
                self.firebaseManager.addNoneStopCollectionListener(to: FirestoreEndpoint.groupMessages($0).ref) { [weak self] in
                    self?.updateTotalUnreadMessages()
                }
                self.firebaseManager.addNoneStopCollectionListener(to: FirestoreEndpoint.groupMembers($0).ref) { [weak self] in
                    self?.updateTotalUnreadMessages()
                }
            }
            privateChatroomIDs.forEach {
                self.firebaseManager.addNoneStopCollectionListener(to: FirestoreEndpoint.messages($0).ref) { [weak self] in
                    self?.updateTotalUnreadMessages()
                }
                self.firebaseManager.addNoneStopCollectionListener(to: FirestoreEndpoint.privateChatroomMembers($0).ref) { [weak self] in
                    self?.updateTotalUnreadMessages()
                }
            }
        }
    }

    func getMessageList(completion: @escaping ((group: [GroupMessageListItem], `private`: [MessageListItem])) -> Void) {
        var blockList = [UserID]()
        var groupMessageItems = [GroupMessageListItem]()
        var friendMessageItems = [MessageListItem]()
        var unknownMessageItems = [MessageListItem]()

        let group = DispatchGroup()
        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            group.enter()
            self.firebaseManager.getBlockList { result in
                switch result {
                case .success(let list):
                    blockList = list
                case .failure(let err):
                    // JProgressHUD.shared.showFailure(view: self.view)
                    blockList = []
                }
                group.leave()
            }

            group.wait()
            group.enter()
            self.firebaseManager.getAllGroupMessages { result in
                switch result {
                case .success(let chatrooms):
                    groupMessageItems = chatrooms
                case .failure(let err):
                    print(err)
                    // JProgressHUD.shared.showFailure(view: self.view)
                }
                group.leave()
            }

            group.enter()
            self.firebaseManager.getAllMessagesCombinedWithSender(type: .friend) { result in
                switch result {
                case .success(let chatrooms):
                    friendMessageItems = chatrooms.filter { !blockList.contains($0.objectID) }
                case .failure(let err):
                    print(err)
                    // JProgressHUD.shared.showFailure(view: self.view)
                }
                group.leave()
            }

            group.enter()
            self.firebaseManager.getAllMessagesCombinedWithSender(type: .unknown) { result in
                switch result {
                case .success(let chatrooms):
                    unknownMessageItems = chatrooms.filter { !blockList.contains($0.objectID) }
                case .failure(let err):
                    print(err)
                    // JProgressHUD.shared.showFailure(view: self.view)
                }
                group.leave()
            }

            group.notify(queue: .main) {
                completion((group: groupMessageItems, private: friendMessageItems + unknownMessageItems))
            }
        }
    }
}
