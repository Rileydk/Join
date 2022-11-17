//
//  OthersProfileViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/4.
//

import UIKit
import ProgressHUD

class OthersProfileViewController: BaseViewController {
    enum Section: CaseIterable {
        case person
    }

    enum Item: Hashable {
        case person(JUser, Relationship)
    }

    typealias ProfileDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: ProfileDatasource!
    let firebaseManager = FirebaseManager.shared
    var objectData: JUser?
    var relationship: Relationship?

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: PersonBasicCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: PersonBasicCell.identifier
            )
            collectionView.setCollectionViewLayout(createLayout(), animated: true)
            configureDatasource()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = objectData?.name
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
    }

    func updateData() {
        updateRelationship { [weak self] result in
            switch result {
            case .success:
                self?.updateDatasource()
            case .failure(let err):
                ProgressHUD.showError()
                print(err)
            }
        }
    }

    func updateRelationship(completion: @escaping (Result<String, Error>) -> Void) {
        firebaseManager.firebaseQueue.async { [weak self] in
            var shouldContinue = true

            let group = DispatchGroup()
            group.enter()
            guard let objectID = self?.objectData?.id else { return }
            self?.firebaseManager.checkIsFriend(id: objectID) { result in
                guard let strongSelf = self else { return }
                switch result {
                case .success:
                    self?.relationship = .friend
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.success("Success"))
                    }
                    shouldContinue = false
                case .failure(let error):
                    print(error)
                    group.leave()
                }
            }

            group.wait()
            if shouldContinue {
                group.enter()
                let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? ""
                self?.firebaseManager.getUserInfo(id: myID) { result in
                    switch result {
                    case .success(let myData):
                        if myData.sentRequests.contains(objectID) {
                            self?.relationship = .sentRequest
                        } else if myData.receivedRequests.contains(objectID) {
                            self?.relationship = .receivedRequest
                        } else {
                            self?.relationship = .unknown
                        }
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.success("Success"))
                        }
                    case .failure(let err):
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(err))
                        }
                    }
                }
            }
        }

        //        let ref = FirestoreEndpoint.mySentRequests.ref
        //        firebaseManager.getSingleDocument(from: ref, match: DocFieldName.id, with: userData?.id) { (result: Result<UserID, Error>) -> Void in
        //            switch result {
        //            case .success(let userID):
        //                print("userID", userID)
        //            case .failure(let err):
        //                print(err)
        //            }
        //        }
    }

    func sendFriendRequest(id: UserID) {
        self.firebaseManager.sendFriendRequest(to: id) { [unowned self] result in
            switch result {
            case .success:
                ProgressHUD.showSuccess()
                self.updateData()
            case .failure(let error):
                ProgressHUD.showFailed()
                print(error)
            }
        }
    }

    func acceptFriendRequest(id: UserID) {
        self.firebaseManager.acceptFriendRequest(from: id) { [unowned self] result in
            switch result {
            case .success:
                ProgressHUD.showSuccess()
                self.updateData()
            case .failure(let error):
                ProgressHUD.showFailed()
                print(error)
            }
        }
    }

    func goChatroom() {
        guard let id = objectData?.id else { return }
        firebaseManager.getChatroom(id: id) { [unowned self] result in
            switch result {
            case .success(let chatroomID):
                let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                guard let chatVC = chatStoryboard.instantiateViewController(
                    withIdentifier: ChatroomViewController.identifier
                ) as? ChatroomViewController else {
                    fatalError("Cannot create chatroom vc")
                }
                chatVC.userData = self.objectData
                chatVC.chatroomID = chatroomID
                self.hidesBottomBarWhenPushed = true
                DispatchQueue.main.async { [unowned self] in
                    self.hidesBottomBarWhenPushed = false
                }
                navigationController?.pushViewController(chatVC, animated: true)
            case .failure(let error):
                print(error)
            }
        }
    }
}

// MARK: - Layout
extension OthersProfileViewController {
    func createPersonSection() -> NSCollectionLayoutSection {
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
        case .person:
            return createPersonSection()
        }
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (index, environment) in
            self?.sectionFor(index: index, environment: environment)
        }
    }
}

// MARK: - Datasource
extension OthersProfileViewController {
    func configureDatasource() {
        // swiftlint:disable line_length
        datasource = ProfileDatasource(collectionView: collectionView) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self?.createCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }
    }

    // swiftlint:disable line_length
    func createCell(collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell {
        switch item {
        case .person(let user, let relationship):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonBasicCell.identifier,
                for: indexPath) as? PersonBasicCell else {
                fatalError("Cannot create personal basic cell")
            }
            cell.layoutCell(withOther: user, relationship: relationship)
            cell.sendFriendRequestHandler = { [unowned self] in
                self.sendFriendRequest(id: user.id)
            }
            cell.acceptFriendRequestHandler = { [unowned self] in
                self.acceptFriendRequest(id: user.id)
            }
            // FIXME: - 確認 unowned
            cell.goChatroomHandler = { [unowned self] in
                self.goChatroom()
            }
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        if let objectData = objectData,
           let relationship = relationship {
            snapshot.appendItems([.person(objectData, relationship)], toSection: .person)
        }

        datasource.apply(snapshot, animatingDifferences: false)
    }
}
