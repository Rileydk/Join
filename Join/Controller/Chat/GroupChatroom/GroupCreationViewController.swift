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
    var groupMembers = [User]()
    var groupChatroom = GroupChatroom(
        id: "", name: "", imageURL: "",
        members: [], admin: "", messages: []
    )
    var groupImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Create", style: .done,
            target: self, action: #selector(createGroup)
        )
    }

    @objc func createGroup() {
        groupMembers.insert(myAccount, at: 0)
        if groupChatroom.name.isEmpty {
            for member in groupMembers {
                groupChatroom.name += member.name
                if member != groupMembers.last {
                    groupChatroom.name += ", "
                }
            }
        }
        groupChatroom.imageURL = myAccount.thumbnailURL
        groupChatroom.members = groupMembers.map { $0.id }
        groupChatroom.admin = myAccount.id

        if let groupImage = groupImage,
           let imageData = groupImage.jpeg(.lowest) {
            firebaseManager.uploadImage(image: imageData) { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let imageURL):
                    strongSelf.groupChatroom.imageURL = imageURL
                    strongSelf.firebaseManager.createGroupChatroom(groupChatroom: strongSelf.groupChatroom) { [weak self] result in
                        switch result {
                        case .success(let chatroomID):
                            print("Successfully create group chatroom")
                            ProgressHUD.showSuccess()

                            let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                            guard let chatroomVC =  chatStoryboard.instantiateViewController(
                                withIdentifier: ChatroomViewController.identifier
                                ) as? ChatroomViewController else {
                                fatalError("Cannot get chatroom vc")
                            }
                            chatroomVC.chatroomID = chatroomID
                            chatroomVC.title = self?.groupChatroom.name

                            guard let rootVC = self?.navigationController?.viewControllers.first! as? ChatListViewController else {
                                fatalError("Cannot get chat list vc")
                            }

                            self?.hidesBottomBarWhenPushed = true
                            DispatchQueue.main.async {
                                self?.hidesBottomBarWhenPushed = false
                            }
                            self?.navigationController?.setViewControllers([rootVC, chatroomVC], animated: true)

                        case .failure(let err):
                            print(err)
                        }
                    }
                case .failure(let err):
                    print(err)
                }
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
