//
//  GroupCreationViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/10.
//

import UIKit
import ProgressHUD

class GroupCreationViewController: BaseViewController {
    enum Section: CaseIterable {
        case header
//        case members
    }

    enum Item: Hashable {
        case header
//        case member(User)
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: GroupCreationHeaderCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: GroupCreationHeaderCell.identifier
            )
            collectionView.setCollectionViewLayout(createLayout(), animated: true)
            configureDatasource()
        }
    }

    typealias GroupDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: GroupDatasource!
    let firebaseManager = FirebaseManager.shared
    var selectedFriends = [User]()
    var groupChatroom = GroupChatroom(
        id: "", name: "", imageURL: "", members: [], admin: ""
    )
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
        selectedFriends.insert(myAccount, at: 0)
        if groupChatroom.name.isEmpty {
            for friend in selectedFriends {
                groupChatroom.name += friend.name
                if friend != selectedFriends.last {
                    groupChatroom.name += ", "
                }
            }
        }
        groupChatroom.members = selectedFriends.map {
            GroupChatMember(id: $0.id, currentStatus: .join)
        }
        groupChatroom.admin = myAccount.id

        firebaseManager.firebaseQueue.async { [weak self] in
            guard let strongSelf = self else { return }

            let group = DispatchGroup()
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
                strongSelf.groupChatroom.imageURL = myAccount.thumbnailURL
                group.leave()
            }

            group.wait()
            group.enter()
            strongSelf.firebaseManager.createGroupChatroom(groupChatroom: strongSelf.groupChatroom) { result in
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
                ProgressHUD.showSuccess()

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
            heightDimension: .fractionalHeight(0.3)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let section = datasource.snapshot().sectionIdentifiers[index]

        switch section {
        case .header:
            return createHeaderSection()
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
        updateDatasource()
    }

    // swiftlint:disable line_length
    func createCell(collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell {
        switch item {
        case .header:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GroupCreationHeaderCell.identifier,
                for: indexPath) as? GroupCreationHeaderCell else {
                fatalError("Cannot create personal basic cell")
            }
            cell.delegate = self
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
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.header], toSection: .header)

        datasource.apply(snapshot, animatingDifferences: false)
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
