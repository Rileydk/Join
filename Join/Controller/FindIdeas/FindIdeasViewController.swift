//
//  ViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/28.
//

import UIKit

class FindIdeasViewController: BaseViewController {
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
    var restProjects = [Project]()

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: FriendProjectCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: FriendProjectCell.identifier
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
        collectionView.backgroundColor = UIColor.Gray6
    }

    func getProjects() {
        var friendsProjects = [Project]()
        var interestProjects = [Project]()

        firebaseManager.firebaseQueue.async { [unowned self] in
            let group = DispatchGroup()
            group.enter()
            self.firebaseManager.getAllProjects { [weak self] result in
                switch result {
                case .success(let projects):
                    self?.projects = projects
                    group.leave()
                case .failure(let error):
                    group.leave()
                    group.notify(queue: .main) {
                        print(error)
                    }
                }
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
                    group.leave()
                case .failure(let error):
                    group.leave()
                    group.notify(queue: .main) {
                        print(error)
                    }
                }
            }

            group.enter()
            // TODO: - 改為使用 UserDefaults 取得興趣類別
            guard let id = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
                fatalError("Doesn't have user id")
            }
            self.firebaseManager.getUserInfo(id: id) { result in
                switch result {
                case .success(let user):
                    interestProjects = self.projects.filter { project in
                        user.interests.contains { interest in
                            project.categories.contains { category in
                                interest == category && project.contact != id
                            }
                        }
                    }
                    group.leave()
                    group.notify(queue: .main) { [unowned self] in
                        recommendedProjects = interestProjects
                        print("recommended:", recommendedProjects)
                        restProjects = projects

//                        recommendedProjects = friendsProjects
//                        recommendedProjects += interestProjects.filter { interestProject in
//                            !recommendedProjects.contains { recommendedProject in
//                                interestProject.projectID == recommendedProject.projectID
//                            }
//                        }
//                        restProjects = projects.filter { project in
//                            !recommendedProjects.contains { recommendedProject in
//                                project.projectID == recommendedProject.projectID
//                            }
//                        }
                        self.updateDatasource()
                    }
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        print(err)
                    }
                }
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
        item.contentInsets = .init(top: 0, leading: 5, bottom: 0, trailing: 5)

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
            heightDimension: .estimated(190)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(28)

        let section = NSCollectionLayoutSection(group: group)
//        section.contentInsets = .init(top: 0, leading: 16, bottom: 20, trailing: 16)
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
                withReuseIdentifier: FriendProjectCell.identifier,
                for: indexPath) as? FriendProjectCell else {
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

        if !recommendedProjects.isEmpty {
            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(recommendedProjects.map { .recommendation($0) }, toSection: .recommendations)
        } else {
            let sections = Array(Section.allCases[1 ..< Section.allCases.count])
            snapshot.appendSections(sections)
        }
        snapshot.appendItems(restProjects.map { .newIdeas($0) }, toSection: .newIdeas)

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Collection View Delegate
extension FindIdeasViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .recommendations:
            performSegue(withIdentifier: SegueIdentifier.GoProjectDetailPage, sender: recommendedProjects[indexPath.row])
        case .newIdeas:
            performSegue(withIdentifier: SegueIdentifier.GoProjectDetailPage, sender: restProjects[indexPath.row])
        }
    }
}
