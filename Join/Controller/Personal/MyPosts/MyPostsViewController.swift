//
//  MyPostsViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/9.
//

import UIKit

class MyPostsViewController: BaseViewController {
    enum Section: CaseIterable {
        case myPosts
    }

    enum Item: Hashable {
        case post(Project)
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(
                UINib(nibName: IdeaCell.identifier, bundle: nil), forCellWithReuseIdentifier: IdeaCell.identifier
            )
            collectionView.setCollectionViewLayout(createLayout(), animated: false)
            collectionView.delegate = self
            configureDataSource()
        }
    }

    typealias PostsDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: PostsDatasource!
    let firebaseManager = FirebaseManager.shared
    var myPosts = [Project]()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getProjects()
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == SegueIdentifier.GoProjectDetailPage {
//            guard let detailVC = segue.destination as? ProjectDetailsViewController,
//                  let project = sender as? Project else {
//                fatalError("Cannot create ProjectDetailsVC")
//            }
//            detailVC.project = project
//        }
//    }

    func layoutViews() {
        title = "我發佈的專案"
    }

    func getProjects() {
        firebaseManager.getAllMyProjectsID { [weak self] result in
            switch result {
            case .success(let postsItems):
                let projectsID = postsItems.map { $0.projectID }
                self?.firebaseManager.getAllMyProjects(projectsID: projectsID) { [weak self] result in
                    switch result {
                    case .success(let posts):
                        self?.myPosts = posts
                        self?.updateDatasource()
                    case .failure(let err):
                        print(err)
                    }
                }
            case .failure(let err):
                print("failed")
                print(err)
            }
        }
    }
}

// MARK: - Layout
extension MyPostsViewController {
    func createPostsSection() -> NSCollectionLayoutSection {
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
        case .myPosts:
            return createPostsSection()
        }
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (index, environment) in
            self?.sectionFor(index: index, environment: environment)
        }
    }
}

// MARK: - Data Source
extension MyPostsViewController {
    func configureDataSource() {
        // swiftlint:disable line_length
        datasource = PostsDatasource(collectionView: collectionView) { [weak self] (collectionView, indexPath, idea) -> UICollectionViewCell? in
            return self?.createCell(collectionView: collectionView, indexPath: indexPath, item: idea)
        }

        updateDatasource()
    }

    // swiftlint:disable line_length
    func createCell(collectionView: UICollectionView ,indexPath: IndexPath, item: Item) -> UICollectionViewCell {
        switch item {
        case .post(let project):
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
        snapshot.appendItems(myPosts.map { .post($0) }, toSection: .myPosts)

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Collection View Delegate
extension MyPostsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .myPosts:
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let detailVC = personalStoryboard.instantiateViewController(withIdentifier: MyPostsDetailViewController.identifier) as? MyPostsDetailViewController else {
                fatalError("Cannot create my post detail vc")
            }
            detailVC.project = myPosts[indexPath.row]
            navigationController?.pushViewController(detailVC, animated: true)
//            performSegue(withIdentifier: SegueIdentifier.GoProjectDetailPage, sender: myPosts[indexPath.row])
        }
    }
}
