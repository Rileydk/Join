//
//  PersonalProfileViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/4.
//

import UIKit

class PersonalProfileViewController: BaseViewController {
    enum Section: CaseIterable {
        case person
    }

    enum Item: Hashable {
        case person(User, UIImage)
    }

    typealias ProfileDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: ProfileDatasource!
    let firebaseManager = FirebaseManager.shared
    var userData: User?
    var userThumbnail: UIImage?

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
        userData = myAccount
        updateData()
    }

    func updateData() {
        getUserThumbnail { [unowned self] in
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
}

// MARK: - Layout
extension PersonalProfileViewController {
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
extension PersonalProfileViewController {
    func configureDatasource() {
        // swiftlint:disable line_length
        datasource = ProfileDatasource(collectionView: collectionView) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self?.createCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }
        updateDatasource()
    }

    // swiftlint:disable line_length
    func createCell(collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell {
        switch item {
        case .person(let user, let image):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonBasicCell.identifier,
                for: indexPath) as? PersonBasicCell else {
                fatalError("Cannot create personal basic cell")
            }
            cell.layoutCell(withSelf: user, image: image)
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        if let userData = userData,
           let userThumbnail = userThumbnail {
            snapshot.appendItems([.person(userData, userThumbnail)], toSection: .person)
        }

        datasource.apply(snapshot, animatingDifferences: false)
    }
}
