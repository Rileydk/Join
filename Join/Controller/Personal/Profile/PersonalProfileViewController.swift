//
//  PersonalProfileViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/4.
//

import UIKit

class PersonalProfileViewController: BaseViewController {
    enum SourceType {
        case normal
        case blockList
        case chatroom
    }

    enum Section: CaseIterable {
        case person
        case buttons
        case introduction
        case skills
//        case interests
        case portfolio
    }

    enum Item: Hashable {
        case person(JUser)
        case buttons(Relationship)
        case introduction(String)
        case skills(String)
//        case interests(String)
        case portfolio(WorkItem)
    }

    typealias ProfileDatasource = UICollectionViewDiffableDataSource<Section, Item>
    private var datasource: ProfileDatasource!
    let firebaseManager = FirebaseManager.shared
    let firestoreManager = FirestoreManager.shared
    let userManager = UserManager.shared

    let cellBackgroundColor: UIColor = .Gray6 ?? .white
    var userID: UserID?
    var userData: JUser?
    var relationship: Relationship?
    var workItems = [WorkItem]()
    var sourceType: SourceType = .normal

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
                UINib(nibName: RelationshipButtonsCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: RelationshipButtonsCell.identifier)
            collectionView.register(
                UINib(nibName: SelfIntroductionCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: SelfIntroductionCell.identifier)
            collectionView.register(
                UINib(nibName: TagCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: TagCell.identifier)
            collectionView.register(
                UINib(nibName: PortfolioCardCell.identifier, bundle: nil),
                forCellWithReuseIdentifier: PortfolioCardCell.identifier)

            collectionView.setCollectionViewLayout(createLayout(), animated: true)
            configureDatasource()
            collectionView.delegate = self
            collectionView.backgroundColor = .Gray6
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setHidesBackButton(true, animated: false)
        guard let navVC = navigationController else { return }
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.Gray1]
        navBarAppearance.backgroundColor = .Gray6
        navBarAppearance.shadowColor = .clear
        navBarAppearance.shadowImage = UIImage()
        navVC.navigationBar.standardAppearance = navBarAppearance
        navVC.navigationBar.scrollEdgeAppearance = navBarAppearance
        navVC.navigationBar.tintColor = .Gray1

        collectionView.addRefreshHeader { [weak self] in
            self?.updateData {
                self?.layoutViews()
            }
        }
        collectionView.beginHeaderRefreshing()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData { [weak self] in
            self?.layoutViews()
        }
    }

    func layoutViews() {
        title = userData?.name
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: JImages.Icon_24px_Back.rawValue), style: .plain,
            target: self, action: #selector(backToPreviousPage))
    }

    func updateData(completion: (() -> Void)? = nil) {
        guard let userID = userID else { fatalError("Doesn't have user id") }

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let group = DispatchGroup()

            group.enter()
            self.userManager.getSingleUserData(userID: userID) { user in
                self.userData = user
                group.leave()
            }

            if let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey), userID != myID {
                group.enter()
                self.userManager.getRelationship(userID: userID) { relationship in
                    self.relationship = relationship
                    group.leave()
                }
            } else {
                self.relationship = .mySelf
            }

            group.enter()
            self.userManager.getPortfolio(userID: userID) { workItems in
                self.workItems = workItems.sorted { $0.latestUpdatedTime > $1.latestUpdatedTime }
                group.leave()
            }

            group.notify(queue: .main) {
                self.updateDatasource()
                self.collectionView.endHeaderRefreshing()
                completion?()
            }
        }
    }

    func editPersonalInfo() {
        let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
        guard let personalProfileEditVC = personalStoryboard.instantiateViewController(
            withIdentifier: PersonalProfileEditViewController.identifier
            ) as? PersonalProfileEditViewController else {
            fatalError("Cannot load personal profile edit vc")
        }

        hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(personalProfileEditVC, animated: true)
    }

    @objc func backToPreviousPage() {
        navigationController?.popViewController(animated: true)
    }

    func sendFriendRequest(userID: UserID?) {
        JProgressHUD.shared.showLoading(text: Constant.Personal.sending, view: view)
        guard let userID = userID else { return }
        userManager.sendFriendRequest(to: userID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.updateData()
                JProgressHUD.shared.showSuccess(view: self.view)
            case .failure(let error):
                print(error)
                JProgressHUD.shared.showFailure(view: self.view)
            }
        }
    }

    func acceptFriendRequest(userID: UserID?) {
        JProgressHUD.shared.showLoading(text: Constant.Personal.sending, view: view)
        guard let userID = userID else { return }
        userManager.acceptFriendRequest(from: userID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.updateData()
                JProgressHUD.shared.showSuccess(view: self.view)
            case .failure(let error):
                print(error)
                JProgressHUD.shared.showFailure(view: self.view)
            }
        }
    }

    func goChatroom() {
        guard let id = userID else { return }

        firebaseManager.getChatroom(id: id) { [unowned self] result in
            switch result {
            case .success(let chatroomID):
                let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                guard let chatVC = chatStoryboard.instantiateViewController(
                    withIdentifier: ChatroomViewController.identifier
                ) as? ChatroomViewController else {
                    fatalError("Cannot create chatroom vc")
                }
                chatVC.userData = userData
                chatVC.chatroomID = chatroomID
                self.hidesBottomBarWhenPushed = true
                DispatchQueue.main.async { [unowned self] in
                    self.hidesBottomBarWhenPushed = false
                }
                navigationController?.pushViewController(chatVC, animated: true)
            case .failure(let error):
                print(error)
            }
        }
    }

    func blockUser() {
        let alert = UIAlertController(title: Constant.Personal.blockAlertTitle,
                                      message: Constant.Personal.blockAlertMessage,
                                      preferredStyle: .actionSheet)
        let yesAction = UIAlertAction(title: Constant.Personal.blockAlertYesActionTitle,
                                      style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            JProgressHUD.shared.showLoading(text: Constant.Common.processing, view: self.view)
            guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey),
                  let userID = self.userID else { return }
            self.firebaseManager.addNewValueToArray(
                ref: FirestoreEndpoint.users.ref.document(myID),
                field: "blockList", values: [userID]) { result in
                switch result {
                case .success:
                    JProgressHUD.shared.showSuccess(text: Constant.Personal.blocked, view: self.view) {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                case .failure(let err):
                    print(err)
                    JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                }
            }
        }
        let cancelAction = UIAlertAction(title: Constant.Personal.blockAlertCancelActionTitle, style: .cancel)

        alert.addAction(yesAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    func reportUser() {
        let alert = UIAlertController(title: Constant.FindIdeas.reportAlert, message: nil, preferredStyle: .actionSheet)
        let yesAction = UIAlertAction(title: Constant.Common.confirm, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            JProgressHUD.shared.showLoading(text: Constant.Common.processing, view: self.view)
            let report = Report(reportID: "", type: .personalProfile, reportedObjectID: self.userID as! String, reportTime: Date(), reason: nil)
            self.firebaseManager.addNewReport(report: report) { result in
                switch result {
                case .success:
                    JProgressHUD.shared.showSuccess(text: Constant.FindIdeas.reportResult, view: self.view)
                case .failure(let err):
                    print(err)
                    JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                }
            }
        }
        let cancelAction = UIAlertAction(title: Constant.Common.cancel, style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(yesAction)
        self.present(alert, animated: true)
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

    func createSkillTagsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(100),
            heightDimension: .absolute(24)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: itemSize.heightDimension
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(8)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = .init(top: 10, leading: 32, bottom: 10, trailing: 32)
        return section
    }

    func createPortfolioSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(260)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 22
        section.contentInsets = .init(top: 0, leading: 32, bottom: 10, trailing: 32)

        if !workItems.isEmpty {
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalHeight(1),
                heightDimension: .absolute(60))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading)
            section.boundarySupplementaryItems = [sectionHeader]
        }

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
        case .skills:
            return createSkillTagsSection()
        case .portfolio:
            return createPortfolioSection()
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

        let headerRegistration = UICollectionView
            .SupplementaryRegistration<CollectionSimpleHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader) { _, _, _ in }
        datasource.supplementaryViewProvider = { [weak self] (_, _, index) in
            self?.collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration, for: index)
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
            cell.layoutCell(user: user, backgroundColor: cellBackgroundColor)
            return cell

        case .buttons:
            if userID == UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) {
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ProfileActionButtonsCell.identifier,
                    for: indexPath) as? ProfileActionButtonsCell else {
                    fatalError("Cannot create person main thumbnail cell")
                }
                cell.layoutCell(backgroundColor: cellBackgroundColor)
                cell.editProfileHandler = { [weak self] in
                    self?.editPersonalInfo()
                }
                return cell

            } else {
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RelationshipButtonsCell.identifier,
                    for: indexPath) as? RelationshipButtonsCell else {
                    fatalError("Cannot create personal basic cell")
                }
                cell.layoutCell(with: relationship, isBlocked: sourceType == .blockList)
                cell.sendFriendRequestHandler = { [weak self] in
                    self?.sendFriendRequest(userID: self?.userID)
                }
                cell.acceptFriendRequestHandler = { [weak self] in
                    self?.acceptFriendRequest(userID: self?.userID)
                }
                cell.goChatroomHandler = { [weak self] in
                    guard let self = self else { return }
                    if self.sourceType == .chatroom {
                        self.dismiss(animated: true)
                    } else {
                        self.goChatroom()
                    }
                }
                cell.blockUserHandler = { [weak self] in
                    self?.blockUser()
                }
                cell.reportUserHandler = { [weak self] in
                    self?.reportUser()
                }
                return cell
            }

        case .introduction(let introduction):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SelfIntroductionCell.identifier,
                for: indexPath) as? SelfIntroductionCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.layoutCell(content: introduction, backgroundColor: cellBackgroundColor)
            return cell

        case .skills(let item):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TagCell.identifier,
                for: indexPath) as? TagCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.layoutCell(item: item)
            return cell

        case .portfolio(let workItem):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PortfolioCardCell.identifier,
                for: indexPath) as? PortfolioCardCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.layoutCell(workItem: workItem)
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        if let userData = userData {
            snapshot.appendItems([.person(userData)], toSection: .person)

            if let relationship = relationship {
                snapshot.appendItems([.buttons(relationship)], toSection: .buttons)
            }

            if !userData.skills.isEmpty {
                snapshot.appendItems(userData.skills.map { .skills($0) }, toSection: .skills)
            }
            if let introduction = userData.introduction, !introduction.isEmpty {
                snapshot.appendItems([.introduction(introduction)], toSection: .introduction)
            }
            if !workItems.isEmpty {
                snapshot.appendItems(workItems.map { .portfolio($0) }, toSection: .portfolio)
            }
        }

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Collection View Delegate
extension PersonalProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let section = Section.allCases[indexPath.section]
        if section == .portfolio {
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            let portfolioDetailVC = personalStoryboard.instantiateViewController(identifier: PortfolioDetailViewController.identifier, creator: { [weak self] coder -> PortfolioDetailViewController? in
                guard let self = self, let userData = self.userData else { return nil }
                return PortfolioDetailViewController(coder: coder, user: userData, workItem: self.workItems[indexPath.row])
            })
            portfolioDetailVC.modalPresentationStyle = .fullScreen
            present(portfolioDetailVC, animated: true)
        }
    }
}
