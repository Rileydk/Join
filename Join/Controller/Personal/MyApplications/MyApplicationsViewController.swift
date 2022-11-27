//
//  MyApplicationsViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/10.
//

import UIKit

class MyApplicationsViewController: BaseViewController {
    enum Section: CaseIterable {
        case myApplications
    }

    enum Item: Hashable {
        case myApplication(Project)
    }

    typealias ApplicationsDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: ApplicationsDatasource!
    let firebaseManager = FirebaseManager.shared
    var projects = [Project]()

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: RecommendedProjectCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: RecommendedProjectCell.identifier
            )
            collectionView.register(
                UINib(nibName: IdeaCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: IdeaCell.identifier
            )
            collectionView.setCollectionViewLayout(createLayout(), animated: true)
            collectionView.delegate = self
            configureDataSource()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMyApplications()
    }

    func layoutViews() {
        title = "我的應徵"
        collectionView.backgroundColor = UIColor.Gray6
    }

    func getMyApplications() {
        firebaseManager.getAllMyApplications { [weak self] result in
            switch result {
            case .success(let projects):
                self?.projects = projects
                self?.updateDatasource()
            case .failure(let err):
                print(err)
            }
        }
    }
}

// MARK: - Layout
extension MyApplicationsViewController {
    func createMyApplicationSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(150)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(150)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Constant.FindIdeas.projectsInterGroupSpacing
        section.contentInsets = Constant.FindIdeas.projectsPageContentInsets
        return section
    }

    func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let section = datasource.snapshot().sectionIdentifiers[index]

        switch section {
        case .myApplications:
            return createMyApplicationSection()
        }
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (index, environment) in
            self?.sectionFor(index: index, environment: environment)
        }
    }
}

// MARK: - Data Source
extension MyApplicationsViewController {
    func configureDataSource() {
        // swiftlint:disable line_length
        datasource = ApplicationsDatasource(collectionView: collectionView) { [weak self] (collectionView, indexPath, idea) -> UICollectionViewCell? in
            return self?.createCell(collectionView: collectionView, indexPath: indexPath, item: idea)
        }

        updateDatasource()
    }

    // swiftlint:disable line_length
    func createCell(collectionView: UICollectionView ,indexPath: IndexPath, item: Item) -> UICollectionViewCell {
        switch item {
        case .myApplication(let project):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IdeaCell.identifier, for: indexPath) as? IdeaCell else {
                fatalError("Cannot create Idea Cell")
            }
            cell.layoutCell(project: project)
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(projects.map { .myApplication($0) }, toSection: .myApplications)

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Collection View Delegate
extension MyApplicationsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .myApplications:
            let findIdeasStoryboard = UIStoryboard(name: StoryboardCategory.findIdeas.rawValue, bundle: nil)
            guard let detailVC = findIdeasStoryboard.instantiateViewController(withIdentifier: ProjectDetailsViewController.identifier) as? ProjectDetailsViewController else {
                fatalError("Cannot create my post detail vc")
            }
            detailVC.sourceType = .myApplications
            detailVC.project = projects[indexPath.row]
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}
