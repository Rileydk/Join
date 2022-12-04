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
                UINib(nibName: IdeaCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: IdeaCell.identifier
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
        title = "我的專案"
        collectionView.backgroundColor = UIColor.Gray6

        let backIcon = UIImage(named: JImages.Icons_24px_Back.rawValue)
        backIcon?.withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: backIcon,
            style: .plain, target: self, action: #selector(backToPreviousPage))
    }

    func getProjects() {
        JProgressHUD.shared.showLoading(view: self.view)

        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            var shouldContinue = true
            var projectsID = [ProjectID]()

            let group = DispatchGroup()
            group.enter()
            self.firebaseManager.getAllMyProjectsItems { result in
                switch result {
                case .success(let postsItems):
                    projectsID = postsItems.map { $0.projectID }
                    guard !projectsID.isEmpty else {
                        // TODO: - 改為顯示提示畫面
                        print("No projects")
                        JProgressHUD.shared.dismiss()
                        shouldContinue = false
                        group.leave()
                        return
                    }
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                        shouldContinue = false
                    }
                }
            }
            group.wait()
            guard shouldContinue else { return }
            group.enter()
            self.firebaseManager.getAllMyProjects(projectsID: projectsID) { result in
                switch result {
                case .success(let posts):
                    group.leave()
                    group.notify(queue: .main) {
                        self.myPosts = posts
                        self.updateDatasource()
                        JProgressHUD.shared.dismiss()
                    }
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                    }
                }
            }
        }
    }

    @objc func backToPreviousPage() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Layout
extension MyPostsViewController {
    func createPostsSection() -> NSCollectionLayoutSection {
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
            cell.layoutCellWithApplicants(project: project)
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

            hidesBottomBarWhenPushed = true
            DispatchQueue.main.async { [weak self] in
                self?.hidesBottomBarWhenPushed = false
            }
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}
