//
//  ViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/28.
//

import UIKit

class FindIdeasViewController: UIViewController {
    enum Section: Hashable {
        case recommendations
        case newIdeas
    }

    enum Item: Hashable {
        case recommendation(Project)
        case newIdeas(Project)
    }

    typealias IdeasDatasource = UICollectionViewDiffableDataSource<Section, Item>
    let firebaseManager = FirebaseManager.shared
    var projects = [Project]()

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: RecommendationCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: RecommendationCell.identifier
            )
            collectionView.register(
                UINib(nibName: IdeaCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: IdeaCell.identifier
            )
        }
    }

    private var datasource: IdeasDatasource!

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firebaseManager.getAllProjects { [weak self] projects in
            self?.projects = projects
            self?.updateDatasource()
        }
    }

    func layoutViews() {
        title = StoryboardCategory.findIdeas.rawValue
        collectionView.setCollectionViewLayout(createLayout(), animated: true)
        configureDataSource()
    }
}

// MARK: - Layout
extension FindIdeasViewController {
    func createRecommendationsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.3),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(0.2)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 20, leading: 16, bottom: 20, trailing: 16)
        section.orthogonalScrollingBehavior = .groupPaging

        return section
    }

    func createNewIdeasSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(220)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    func sectionFor(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let section = datasource.snapshot().sectionIdentifiers[index]

        switch section {
        case .recommendations:
            return createRecommendationsSection()
        case .newIdeas:
            return createNewIdeasSection()
        }
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (index, environment) in
            self?.sectionFor(index: index, environment: environment)
        }
    }
}

// MARK: - Data Source
extension FindIdeasViewController {
    func configureDataSource() {
        // swiftlint:disable line_length
        datasource = IdeasDatasource(collectionView: collectionView) { [weak self] (collectionView, indexPath, idea) -> UICollectionViewCell? in

            self?.createCell(collectionView: collectionView, indexPath: indexPath, item: idea)
        }
        updateDatasource()
    }

    // swiftlint:disable line_length
    func createCell(collectionView: UICollectionView ,indexPath: IndexPath, item: Item) -> UICollectionViewCell {
        switch item {
        case .recommendation(let data):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RecommendationCell.identifier,
                for: indexPath) as? RecommendationCell else {
                fatalError("Cannot create Recommendation Cell")
            }
            cell.layoutCell(project: data)
            return cell
        case .newIdeas(let data):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IdeaCell.identifier, for: indexPath) as? IdeaCell else {
                fatalError("Cannot create Idea Cell")
            }
            cell.layoutCell(project: data)
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.recommendations, .newIdeas])
        // TODO: - 取得資料 -> 改用 Result Type
        snapshot.appendItems(projects.map { .recommendation($0) }, toSection: .recommendations)
        snapshot.appendItems(projects.map { .newIdeas($0) }, toSection: .newIdeas)

        print(datasource)
        datasource.apply(snapshot, animatingDifferences: false)
    }
}
