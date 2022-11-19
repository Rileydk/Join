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
        case buttons
        case introduction
//        case skills
//        case interests
//        case portfolio
    }

    enum Item: Hashable {
        case person(JUser)
        case buttons
        case introduction(String)
//        case skills([String])
//        case interests([String])
//        case portfolio(WorkItem)
    }

    typealias ProfileDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: ProfileDatasource!
    let firebaseManager = FirebaseManager.shared
    var userData: JUser? {
        didSet {
            layoutViews()
        }
    }
    var workItems = [WorkItem]()

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: PersonalMainThumbnailCollectionCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: PersonalMainThumbnailCollectionCell.identifier
            )
            collectionView.register(
                UINib(nibName: ProfileActionButtonsCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: ProfileActionButtonsCell.identifier)
            collectionView.register(
                UINib(nibName: SelfIntroductionCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: SelfIntroductionCell.identifier)
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
//        navigationItem.rightBarButtonItem = UIBarButtonItem(
//            image: UIImage(systemName: "pencil"), style: .plain,
//            target: self, action: #selector(editPersonalInfo))
    }

    func updateData() {
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have user id")
        }

        JProgressHUD.shared.showLoading(view: self.view)

        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            self.firebaseManager.getUserInfo(id: myID) { result in
                switch result {
                case .success(let userData):
                    self.userData = userData
                case .failure(let err):
                    print(err)
                    JProgressHUD.shared.showFailure(view: self.view)
                }
            }

            let group = DispatchGroup()

            var shouldContinue = true
            group.enter()
            self.firebaseManager.getMyWorks { result in
                switch result {
                case .success(let works):
                    self.workItems = works.map {
                        WorkItem(workID: $0.workID, name: $0.name,
                                 description: $0.description,
                                 latestUpdatedTime: $0.latestUpdatedTime, records: [])
                    }
                    group.leave()
                case .failure(let err):
                    JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                    shouldContinue = false
                    group.leave()
                }
            }

            group.wait()
            guard shouldContinue else { return }
            for i in 0 ..< self.workItems.count {
                guard shouldContinue else { return }
                group.enter()
                self.firebaseManager.getMyWorkRecords(by: self.workItems[i].workID) { result in
                    switch result {
                    case .success(let records):
                        self.workItems[i].records = records
                        group.leave()
                    case .failure(let err):
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                        shouldContinue = false
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) {
                self.updateDatasource()
                JProgressHUD.shared.dismiss()
            }
        }
    }

    @objc func editPersonalInfo() {
        let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
        guard let personalProfileEditVC = personalStoryboard.instantiateViewController(
            withIdentifier: PersonalProfileEditViewController.identifier
            ) as? PersonalProfileEditViewController else {
            fatalError("Cannot load personal profile edit vc")
        }

        navigationController?.pushViewController(personalProfileEditVC, animated: true)
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
            heightDimension: .absolute(180)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    func createActionButtonsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(60)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    func createIntroductionSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(100)
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
        case .buttons:
            return createActionButtonsSection()
        case .introduction:
            return createIntroductionSection()
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
                withReuseIdentifier: PersonalMainThumbnailCollectionCell.identifier,
                for: indexPath) as? PersonalMainThumbnailCollectionCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.layoutCell(user: user)
            return cell

        case .buttons:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProfileActionButtonsCell.identifier,
                for: indexPath) as? ProfileActionButtonsCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.editProfileHandler = { [weak self] in
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                guard let personalProfileEditVC = personalStoryboard.instantiateViewController(
                    withIdentifier: PersonalProfileEditViewController.identifier
                    ) as? PersonalProfileEditViewController else {
                    fatalError("Cannot load personal profile edit vc")
                }
                self?.navigationController?.pushViewController(personalProfileEditVC, animated: true)
            }
            return cell

        case .introduction(let introduction):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SelfIntroductionCell.identifier,
                for: indexPath) as? SelfIntroductionCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.layoutCell(content: introduction)
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        if let userData = userData {
            snapshot.appendItems([.person(userData)], toSection: .person)
            snapshot.appendItems([.buttons], toSection: .buttons)
        }
        if let introduction = userData?.introduction, !introduction.isEmpty {
            snapshot.appendItems([.introduction(introduction)], toSection: .introduction)
        }

        datasource.apply(snapshot, animatingDifferences: false)
    }
}
