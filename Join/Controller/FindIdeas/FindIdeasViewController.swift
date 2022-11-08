//
//  ViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/28.
//

import UIKit

class FindIdeasViewController: UIViewController {
    enum Section: CaseIterable {
        case recommendations
        case newIdeas
    }

    enum Item: Hashable {
        case recommendation(Project)
        case newIdeas(Project)
    }

    typealias IdeasDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: IdeasDatasource!
    let firebaseManager = FirebaseManager.shared
    var projects = [Project]()
    var recommendedProjects = [Project]()

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
        getProjects()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.GoProjectDetailPage {
            guard let detailVC = segue.destination as? ProjectDetailsViewController,
                  let project = sender as? Project else {
                fatalError("Cannot create ProjectDetailsVC")
            }
            detailVC.project = project
        }
    }

    func layoutViews() {
        title = Tab.findIdeas.title
    }

    func getProjects() {
        var friendsProjects = [Project]()
        var interestProjects = [Project]()

        DispatchQueue.global().async { [unowned self] in
            let group = DispatchGroup()
            group.enter()
            self.firebaseManager.getAllProjects { [weak self] result in
                switch result {
                case .success(let projects):
                    self?.projects = projects
                case .failure(let error):
                    print(error)
                }
                group.leave()
            }

            group.wait()
            group.enter()
            self.firebaseManager.getAllFriendsAndChatroomsInfo(type: .friend) { [unowned self] result in
                switch result {
                case .success(let friends):
                    friendsProjects = self.projects.filter { project in
                        friends.contains { friend in
                            project.contact == friend.id
                        }
                    }
                case .failure(let error):
                    print(error)
                }
                group.leave()
            }

            // 取回所有興趣
            group.enter()
            self.firebaseManager.getAllInterests { result in
                switch result {
                case .success(let interests):
                    interestProjects = self.projects.filter { project in
                        interests.contains { interest in
                            project.categories.contains { $0 == interest }
                        }
                    }

                case .failure(let error):
                    print(error)
                }
                group.leave()
            }

            group.notify(queue: .main) { [unowned self] in
                let hots = friendsProjects + interestProjects
                let overlap = Set(hots)
                let whole = Set(self.projects)
                let rest = whole.subtracting(overlap)
                self.recommendedProjects = Array(overlap)
                self.projects = Array(rest)

                self.updateDatasource()
            }
        }
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
            return self?.createCell(collectionView: collectionView, indexPath: indexPath, item: idea)
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
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(recommendedProjects.map { .recommendation($0) }, toSection: .recommendations)
        snapshot.appendItems(projects.map { .newIdeas($0) }, toSection: .newIdeas)

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Collection View Delegate
extension FindIdeasViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifier.GoProjectDetailPage, sender: projects[indexPath.row])
    }
}
