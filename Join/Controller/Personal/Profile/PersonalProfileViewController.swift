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
    let cellBackgroundColor: UIColor = .Gray6 ?? .white
    var userID: UserID?
    var userData: JUser?
    var relationship: Relationship?
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
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setHidesBackButton(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData { [weak self] in
            self?.layoutViews()
        }
    }

    func layoutViews() {
        title = userData?.name
        collectionView.backgroundColor = .Gray6
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: JImages.Icons_24px_Back.rawValue), style: .plain,
            target: self, action: #selector(backToPreviousPage))
    }

    func updateData(completion: (() -> Void)? = nil) {
        guard let userID = userID else {
            fatalError("Doesn't have user id")
        }

        JProgressHUD.shared.showLoading(view: self.view)

        let group = DispatchGroup()
        var shouldContinue = true

        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            group.enter()
            self.firebaseManager.getUserInfo(id: userID) { result in
                switch result {
                case .success(let userData):
                    self.userData = userData
                    group.leave()
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                        shouldContinue = false
                    }
                }
            }

            if userID != UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) {
                group.enter()
                self.getRelationship { result in
                    switch result {
                    case .success:
                        group.leave()
                    case .failure(let err):
                        group.leave()
                        group.notify(queue: .main) {
                            JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                            shouldContinue = false
                        }
                    }
                }
            } else {
                self.relationship = .mySelf
            }

            group.enter()
            self.firebaseManager.getUserWorks(userID: userID) { result in
                switch result {
                case .success(let works):
                    self.workItems = works.map {
                        WorkItem(workID: $0.workID, name: $0.name,
                                 description: $0.description,
                                 latestUpdatedTime: $0.latestUpdatedTime, records: [])
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
            for i in 0 ..< self.workItems.count {
                guard shouldContinue else { break }
                group.enter()
                self.firebaseManager.getWorkRecords(userID: userID, by: self.workItems[i].workID) { result in
                    switch result {
                    case .success(let records):
                        self.workItems[i].records = records
                        group.leave()
                    case .failure(let err):
                        print(err)
                        shouldContinue = false
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main) {
                if shouldContinue {
                    self.updateDatasource()
                    JProgressHUD.shared.dismiss()
                    completion?()
                } else {
                    JProgressHUD.shared.showFailure(view: self.view)
                }
            }
        }
    }

    func getRelationship(completion: @escaping (Result<String, Error>) -> Void) {
        firebaseManager.firebaseQueue.async { [weak self] in
            var shouldContinue = true

            let group = DispatchGroup()
            group.enter()
            guard let objectID = self?.userID else { return }
            self?.firebaseManager.checkIsFriend(id: objectID) { result in
                switch result {
                case .success:
                    self?.relationship = .friend
                    shouldContinue = false
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.success("Success"))
                    }
                case .failure(let error):
                    print(error)
                    group.leave()
                }
            }

            group.wait()
            guard shouldContinue else { return }
            group.enter()
            let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? ""
            self?.firebaseManager.getUserInfo(id: myID) { result in
                switch result {
                case .success(let myData):
                    if myData.sentRequests.contains(objectID) {
                        self?.relationship = .sentRequest
                    } else if myData.receivedRequests.contains(objectID) {
                        self?.relationship = .receivedRequest
                    } else {
                        self?.relationship = .unknown
                    }
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.success("Success"))
                    }
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                }
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

        navigationController?.pushViewController(personalProfileEditVC, animated: true)
    }

    @objc func backToPreviousPage() {
        navigationController?.popViewController(animated: true)
    }

    func sendFriendRequest(id: UserID?) {
        guard let id = id else { fatalError("Cannot get userID") }
        self.firebaseManager.sendFriendRequest(to: id) { [unowned self] result in
            switch result {
            case .success:
                self.updateData()
            case .failure(let error):
                print(error)
            }
        }
    }

    func acceptFriendRequest(id: UserID?) {
        guard let id = id else { fatalError("Cannot get userID") }
        self.firebaseManager.acceptFriendRequest(from: id) { [unowned self] result in
            switch result {
            case .success:
                self.updateData()
            case .failure(let error):
                print(error)
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
        section.interGroupSpacing = 12
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
                cell.layoutCell(with: relationship)
                cell.sendFriendRequestHandler = { [weak self] in
                    self?.sendFriendRequest(id: self?.userID)
                }
                cell.acceptFriendRequestHandler = { [weak self] in
                    self?.acceptFriendRequest(id: self?.userID)
                }
                cell.goChatroomHandler = { [weak self] in
                    self?.goChatroom()
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
        print("see work detail")
    }
}
