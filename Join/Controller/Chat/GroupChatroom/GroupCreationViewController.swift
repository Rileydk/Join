//
//  GroupCreationViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/10.
//

import UIKit

class GroupCreationViewController: BaseViewController {
    enum Section: CaseIterable {
        case header
        case members
    }

    enum Item: Hashable {
        case header(String)
        case member(JUser)
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: GroupCreationHeaderCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: GroupCreationHeaderCell.identifier)
            collectionView.register(
                UINib(nibName: GroupMemberCircleCollectionViewCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: GroupMemberCircleCollectionViewCell.identifier)
            collectionView.register(
                UINib(nibName: AddNewMemberCircleCollectionViewCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: AddNewMemberCircleCollectionViewCell.identifier)
//            collectionView.register(BadgeSupplementaryView.self, forSupplementaryViewOfKind: "badge-element-kind", withReuseIdentifier: BadgeSupplementaryView.identifier)
            collectionView.setCollectionViewLayout(createLayout(), animated: true)
            collectionView.delegate = self
            configureDatasource()
            collectionView.backgroundColor = .Gray6
        }
    }

    typealias GroupDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: GroupDatasource!
    let firebaseManager = FirebaseManager.shared
    var selectedFriends = [JUser]() {
        didSet {
            if collectionView != nil {
                updateDatasource()
            }
        }
    }
    var groupChatroom = GroupChatroom(
        id: "", name: "", imageURL: "", admin: "", createdTime: Date()
    )
    var defaultGroupName: String {
        var defaultGroupName = "\(UserDefaults.standard.string(forKey: UserDefaults.UserKey.userNameKey)!)"
        if !selectedFriends.isEmpty {
            for friend in selectedFriends {
                defaultGroupName += ", \(friend.name)"
            }
        }
        return defaultGroupName
    }
    var selectedMembers = [ChatroomMember]()
    var groupImage: UIImage?
    var chatroomID: ChatroomID?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Create", style: .done,
            target: self, action: #selector(createGroup)
        )
    }

    @objc func createGroup() {
        firebaseManager.firebaseQueue.async { [weak self] in
            guard let strongSelf = self else { return }

            let group = DispatchGroup()
            group.enter()
            let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? ""
            self?.firebaseManager.getUserInfo(id: myID) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let userData):
                    var selectedFriends = self.selectedFriends
                    selectedFriends.insert(userData, at: 0)
                    if self.groupChatroom.name.isEmpty {
                        self.groupChatroom.name = self.defaultGroupName
                    }
                    self.selectedMembers = selectedFriends.map {
                        ChatroomMember(
                            userID: $0.id, currentMemberStatus: .join,
                            currentInoutStatus: .out, lastTimeInChatroom: Date()
                        )
                    }
                    self.groupChatroom.admin = userData.id
                    group.leave()
                case .failure(let err):
                    print(err)
                    group.leave()
                }
            }

            group.enter()
            if let groupImage = self?.groupImage,
               let imageData = groupImage.jpeg(.lowest) {
                strongSelf.firebaseManager.uploadImage(image: imageData) { [weak self] result in
                    guard let strongSelf = self else { return }
                    switch result {
                    case .success(let imageURL):
                        strongSelf.groupChatroom.imageURL = imageURL
                        group.leave()
                    case .failure(let err):
                        group.leave()
                        group.notify(queue: .main) {
                            print(err)
                        }
                    }
                }
            } else {
                strongSelf.groupChatroom.imageURL = UserDefaults.standard.string(forKey: UserDefaults.UserKey.userThumbnailURLKey) ?? FindPartnersFormSections.placeholderImageURL
                group.leave()
            }

            group.wait()
            group.enter()
            strongSelf.firebaseManager.createGroupChatroom(groupChatroom: strongSelf.groupChatroom, members: strongSelf.selectedMembers) { result in
                switch result {
                case .success(let chatroomID):
                    strongSelf.chatroomID = chatroomID
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        print(err)
                    }
                }
            }

            group.notify(queue: .main) {
                let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                guard let chatroomVC =  chatStoryboard.instantiateViewController(
                    withIdentifier: GroupChatroomViewController.identifier
                ) as? GroupChatroomViewController else {
                    fatalError("Cannot get chatroom vc")
                }
                chatroomVC.chatroomID = strongSelf.chatroomID
                chatroomVC.title = strongSelf.groupChatroom.name

                guard let rootVC = strongSelf.navigationController?.viewControllers.first! as? ChatListViewController else {
                    fatalError("Cannot get chat list vc")
                }

                self?.hidesBottomBarWhenPushed = true
                DispatchQueue.main.async {
                    self?.hidesBottomBarWhenPushed = false
                }
                self?.navigationController?.setViewControllers([rootVC, chatroomVC], animated: true)
            }
        }
    }
}

extension GroupCreationViewController {
    func createHeaderSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(130)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    func createGroupMemberSelectionSection() -> NSCollectionLayoutSection {
//        let anchorEdges: NSDirectionalRectEdge = [.top, .trailing]
//        let offset = CGPoint(x: 0.3, y: -0.3)
//        let badgeAnchor = NSCollectionLayoutAnchor(edges: anchorEdges, fractionalOffset: offset)
//        let badgeSize = NSCollectionLayoutSize(widthDimension: .absolute(20), heightDimension: .absolute(20))
//        let badge = NSCollectionLayoutSupplementaryItem(layoutSize: badgeSize, elementKind: "badge-element-kind", containerAnchor: badgeAnchor)

        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(50),
                                              heightDimension: .estimated(130))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize, supplementaryItems: [badge])
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(104))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 20, leading: 20, bottom: 20, trailing: 20)
        return section
    }

    func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let section = datasource.snapshot().sectionIdentifiers[index]

        switch section {
        case .header:
            return createHeaderSection()
        case .members:
            return createGroupMemberSelectionSection()
        }
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (index, environment) in
            self?.sectionFor(index: index, environment: environment)
        }
    }
}

// MARK: - Datasource
extension GroupCreationViewController {
    func configureDatasource() {
        // swiftlint:disable line_length
        datasource = GroupDatasource(collectionView: collectionView) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self?.createCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }

//        datasource.supplementaryViewProvider = { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
//
//            guard let badgeView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BadgeSupplementaryView.identifier, for: indexPath) as? BadgeSupplementaryView else {
//                return nil
//            }
//            return badgeView
//        }

        updateDatasource()
    }

    // swiftlint:disable line_length
    func createCell(collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell {
        switch item {
        case .header(let groupName):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GroupCreationHeaderCell.identifier,
                for: indexPath) as? GroupCreationHeaderCell else {
                fatalError("Cannot create personal basic cell")
            }
            cell.delegate = self
            if let userImageURL = UserDefaults.standard.string(forKey: UserDefaults.UserKey.userThumbnailURLKey) {
                cell.layoutCell(defaultGroupName: groupName, imageURL: userImageURL)
            }
            cell.alertPresentHandler = { [weak self] alert in
                self?.present(alert, animated: true)
            }
            cell.cameraPresentHandler = { [weak self] controller in
                self?.present(controller, animated: true)
            }
            cell.libraryPresentHandler = { [weak self] picker in
                self?.present(picker, animated: true)
            }
            return cell

        case .member(let user):
            if indexPath.row == 0 {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddNewMemberCircleCollectionViewCell.identifier, for: indexPath) as? AddNewMemberCircleCollectionViewCell else {
                    fatalError("Cannot create add new member circle collection view cell")
                }
                return cell

            } else {

                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupMemberCircleCollectionViewCell.identifier, for: indexPath) as? GroupMemberCircleCollectionViewCell else {
                    fatalError("Cannot create group member circle collection view cell")
                }
                cell.layoutCell(user: user)
                if indexPath.row == 1{
                    cell.deleteBadgeButton.isHidden = true
                }
                cell.deleteHandler = { [weak self] in
                    self?.selectedFriends.remove(at: indexPath.row - 2)
                }
                return cell
            }
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.header(defaultGroupName)], toSection: .header)
        let myUserData = JUser(
            id: UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)!,
            name: UserDefaults.standard.string(forKey: UserDefaults.UserKey.userNameKey)!,
            email: "",
            thumbnailURL: UserDefaults.standard.string(forKey: UserDefaults.UserKey.userThumbnailURLKey)!)
        snapshot.appendItems([.member(JUser.mockUser), .member(myUserData)] + selectedFriends.map { .member($0) }, toSection: .members)

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Collection View Delegate
extension GroupCreationViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = Section.allCases[indexPath.section]
        if section == .members && indexPath.row == 0 {
            let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
            guard let friendSelectionVC = chatStoryboard.instantiateViewController(
                withIdentifier: FriendSelectionViewController.identifier
                ) as? FriendSelectionViewController else {
                fatalError("Cannot create friend selection vc")
            }
            friendSelectionVC.selectedFriends = selectedFriends
            friendSelectionVC.source = .secondStepWhenCreateNewGroupChat
            friendSelectionVC.addToMemberSelectionHandler = { [weak self] newSelectedFriends in
                self?.selectedFriends = newSelectedFriends
            }
            navigationController?.pushViewController(friendSelectionVC, animated: true)
        }
    }
}

// MARK: - Group Image Picker Cell Delegate
extension GroupCreationViewController: GroupCreationHeaderCellDelegate {
    func groupCreationHeaderCell(_ cell: GroupCreationHeaderCell, didAddName name: String) {
        groupChatroom.name = name
    }

    func groupCreationHeaderCell(_ cell: GroupCreationHeaderCell, didSetImage image: UIImage) {
        groupImage = image
    }
}
