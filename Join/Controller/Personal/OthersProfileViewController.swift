//
//  OthersProfileViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/4.
//

import UIKit
import ProgressHUD

class OthersProfileViewController: UIViewController {
    static let identifier = String(describing: OthersProfileViewController.self)

    enum Section: CaseIterable {
        case person
    }

    enum Item: Hashable {
        case person(User, UIImage, Relationship)
    }

    typealias ProfileDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: ProfileDatasource!
    let firebaseManager = FirebaseManager.shared
    var userData: User?
    var userThumbnail: UIImage?
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
        title = userData?.name
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
    }

    func updateData() {
        let group = DispatchGroup()
        group.enter()
        getUserThumbnail {
            group.leave()
        }
        group.enter()
        updateRelationship {
            group.leave()
        }
        group.enter()
        updateUserData {
            group.leave()
        }
        group.notify(queue: .main) { [unowned self] in
            self.updateDatasource()
        }
    }

    func getUserThumbnail(completion: @escaping () -> Void) {
        guard let imageURL = userData?.thumbnailURL else { return }
        firebaseManager.downloadImage(urlString: imageURL) { [unowned self] result in
            switch result {
            case .success(let image):
                self.userThumbnail = image
                completion()
            case .failure(let error):
                print(error)
                completion()
            }
        }
    }

    func updateRelationship(completion: @escaping () -> Void) {
        firebaseManager.getUserInfo(id: myAccount.id) { [unowned self] result in
            guard let user = userData?.id else { return }
            switch result {
            case .success(let myInfo):
                if myInfo.friends.contains(user) {
                    self.relationship = .friend
                } else if myInfo.sentRequests.contains(user) {
                    self.relationship = .sentRequest
                } else if myInfo.receivedRequests.contains(user) {
                    self.relationship = .receivedRequest
                } else {
                    self.relationship = .unknown
                }
                completion()
            case .failure(let error):
                print(error)
                completion()
            }
        }
    }

    func updateUserData(completion: @escaping () -> Void) {
        guard let id = userData?.id else { return }
        firebaseManager.getUserInfo(id: id) { [unowned self] result in
            switch result {
            case .success(let userData):
                self.userData = userData
                completion()
            case .failure(let error):
                print(error)
                completion()
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
//        updateDatasource()
    }

    // swiftlint:disable line_length
    func createCell(collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell {
        switch item {
        case .person(let user, let image, let relationship):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonBasicCell.identifier,
                for: indexPath) as? PersonBasicCell else {
                fatalError("Cannot create personal basic cell")
            }
            cell.layoutCell(withOther: user, thumbnail: image, relationship: relationship)
            cell.sendFriendRequestHandler = { [unowned self] in
                self.firebaseManager.sendFriendRequest(to: user.id) { [unowned self] result in
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
            cell.acceptFriendRequestHandler = { [unowned self] in
                self.firebaseManager.acceptFriendRequest(from: user.id) { [unowned self] result in
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
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        if let userData = userData,
           let userThumbnail = userThumbnail,
           let relationship = relationship {
            snapshot.appendItems([.person(userData, userThumbnail, relationship)], toSection: .person)
        }

        datasource.apply(snapshot, animatingDifferences: false)
    }
}
