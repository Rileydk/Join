//
//  MyApplicationsViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/10.
//

import UIKit

class MyRelatedProjectsViewController: BaseViewController {
    enum ProjectsType {
        case applications
        case collections
    }

    enum Section: CaseIterable {
        case projects
    }

    enum Item: Hashable {
        case project(Project)
    }

    typealias ApplicationsDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: ApplicationsDatasource!
    let firebaseManager = FirebaseManager.shared
    var projects = [Project]()
    var projectsType: ProjectsType = .applications

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
        collectionView.addRefreshHeader { [weak self] in
            self?.getRelatedProjects()
        }
        collectionView.beginHeaderRefreshing()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavBarAppearance(to: .dark)
        getRelatedProjects()
    }

    func layoutViews() {
        title = "ζηζεΎ΅"
        collectionView.backgroundColor = UIColor.Gray6
    }

    func getRelatedProjects() {
        var type: ProjectDocumentArrayFieldType = .applicants
        switch projectsType {
        case .applications: type = .applicants
        case .collections: type = .collectors
        }
        firebaseManager.getAllMyRelativeInfoInDocuments(type: type) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let projects):
                self.projects = projects
                self.collectionView.endHeaderRefreshing()
                self.updateDatasource()
            case .failure(let err):
                print(err)
            }
        }
    }
}

// MARK: - Layout
extension MyRelatedProjectsViewController {
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
        case .projects:
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
extension MyRelatedProjectsViewController {
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
        case .project(let project):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IdeaCell.identifier, for: indexPath) as? IdeaCell else {
                fatalError("Cannot create Idea Cell")
            }
            cell.layoutCell(project: project)
            cell.saveHandler = { [weak self] (action, project) in
                guard let self = self,
                      let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else { return }
                let ref = FirestoreEndpoint.projects.ref.document(project.projectID)
                let fieldName = ProjectDocumentArrayFieldType.collectors.rawValue
                JProgressHUD.shared.showSaving(view: self.view)
                switch action {
                case .save:
                    self.firebaseManager.addNewValueToArray(ref: ref, field: fieldName, values: [myID]) { result in
                        switch result {
                        case .success:
                            self.getRelatedProjects()
                            JProgressHUD.shared.showSuccess(text: Constant.Personal.saveSuccessfully, view: self.view)
                        case .failure(let err):
                            print(err)
                            JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                        }
                    }
                case .remove:
                    self.firebaseManager.removeValueOfArray(ref: ref, field: fieldName, values: [myID]) { result in
                        switch result {
                        case .success:
                            self.getRelatedProjects()
                            JProgressHUD.shared.showSuccess(text: Constant.Personal.removeSuccessfully, view: self.view)
                        case .failure(let err):
                            print(err)
                            JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                        }
                    }
                }
            }
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(projects.map { .project($0) }, toSection: .projects)

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Collection View Delegate
extension MyRelatedProjectsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .projects:
            let findIdeasStoryboard = UIStoryboard(name: StoryboardCategory.findIdeas.rawValue, bundle: nil)
            guard let detailVC = findIdeasStoryboard.instantiateViewController(withIdentifier: ProjectDetailsViewController.identifier) as? ProjectDetailsViewController else {
                fatalError("Cannot create my post detail vc")
            }
            detailVC.sourceType = .myApplications
            detailVC.project = projects[indexPath.row]
            hidesBottomBarWhenPushed = true
            DispatchQueue.main.async { [weak self] in
                self?.hidesBottomBarWhenPushed = false
            }
            navigationItem.backButtonDisplayMode = .minimal
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}
