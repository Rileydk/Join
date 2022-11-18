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
//        case skills
//        case interests
//        case portfolio
    }

    enum Item: Hashable {
        case person(JUser)
//        case skills([String])
//        case interests([String])
//        case portfolio([Masterpiece])
    }

    typealias ProfileDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: ProfileDatasource!
    let firebaseManager = FirebaseManager.shared
    var userData: JUser? {
        didSet {
            layoutViews()
        }
    }

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
    }

    func layoutViews() {
        title = userData?.name
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .plain, target: self, action: #selector(editPersonalInfo)),
            UIBarButtonItem(image: UIImage(systemName: "plus.app"), style: .plain, target: self, action: #selector(addPortfolio))
        ]
    }

    func updateData() {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }
        firebaseManager.getUserInfo(id: myID) { [weak self] result in
            switch result {
            case .success(let userData):
                self?.userData = userData
                self?.updateDatasource()
            case .failure(let err):
                print(err)
            }
        }
    }

    @objc func editPersonalInfo() {
        let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
        guard let personalProfileEditVC = personalStoryboard.instantiateViewController(withIdentifier: PersonalProfileEditViewController.identifier) as? PersonalProfileEditViewController else {
            fatalError("Cannot load personal profile edit vc")
        }
        
        navigationController?.pushViewController(personalProfileEditVC, animated: true)
    }

    @objc func addPortfolio() {

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
        case .person(let user):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonBasicCell.identifier,
                for: indexPath) as? PersonBasicCell else {
                fatalError("Cannot create personal basic cell")
            }
            cell.layoutCell(withSelf: user)
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        if let userData = userData {
            snapshot.appendItems([.person(userData)], toSection: .person)
        }

        datasource.apply(snapshot, animatingDifferences: false)
    }
}
