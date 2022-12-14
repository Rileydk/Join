//
//  MyPostsDetailViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/9.
//

import UIKit

class MyPostsDetailViewController: BaseViewController {
    enum Section: CaseIterable {
        case bigImage
        case projectName
        // case categories
        case recruiting
        case skills
        case deadline
        case essentialLocation
        case description
        // case group
        // case location
        case applicants
        case noApplicant
        case groupButton
    }

    enum Item: Hashable {
        case bigImage(URLString)
        case projectName(Project)
        //        case categories
        case recruiting(Project)
        case skills(Project)
        case deadline(Project)
        case essentialLocation(Project)
        case description(Project)
        //        case group
        //        case location
        case applicant(Applicant)
        case noApplicant
        case groupButton(Project)
    }

    typealias ProjectDetailsDatasource = UITableViewDiffableDataSource<Section, Item>
    private var datasource: ProjectDetailsDatasource!
    let firebaseManager = FirebaseManager.shared
    var project: Project?
    var applicants = [JUser]()

    struct Applicant: Hashable {
        let user: JUser
        let isMember: Bool
    }
    var adjustedApplicants: [Applicant] {
        return applicants.map { applicant in
            Applicant(user: applicant, isMember: project!.members.contains { member in
                member.id == applicant.id
            })
        }
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: BigImageCell.identifier, bundle: nil),
                forCellReuseIdentifier: BigImageCell.identifier
            )
            tableView.register(
                UINib(nibName: ProjectTitleCell.identifier, bundle: nil),
                forCellReuseIdentifier: ProjectTitleCell.identifier)
            tableView.register(
                UINib(nibName: ProjectItemCell.identifier, bundle: nil),
                forCellReuseIdentifier: ProjectItemCell.identifier)
            tableView.register(
                UINib(nibName: MultilineCell.identifier, bundle: nil),
                forCellReuseIdentifier: MultilineCell.identifier)
            tableView.register(
                UINib(nibName: ContactCell.identifier, bundle: nil),
                forCellReuseIdentifier: ContactCell.identifier
            )
            tableView.register(
                UINib(nibName: DetailTitleHeaderView.identifier, bundle: nil),
                forHeaderFooterViewReuseIdentifier: DetailTitleHeaderView.identifier
            )
            tableView.register(
                UINib(nibName: NoApplicantTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: NoApplicantTableViewCell.identifier)
            tableView.register(
                UINib(nibName: JoinButtonCell.identifier, bundle: nil),
                forCellReuseIdentifier: JoinButtonCell.identifier
            )

            tableView.delegate = self
            configureDatasource()

            tableView.separatorStyle = .none
            tableView.allowsSelection = false
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 80
            if #available(iOS 15, *) {
                tableView.sectionHeaderTopPadding = 0
            }
            tableView.backgroundColor = .Gray6
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let backIcon = UIImage(named: JImages.Icon_24px_Back.rawValue)
        backIcon?.withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: backIcon,
            style: .plain, target: self, action: #selector(backToPreviousPage))
        guard let project = project else { return }
        title = project.name

        tableView.addRefreshHeader { [weak self] in
            self?.updateData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.White]
        navBarAppearance.backgroundColor = .Blue1
        navBarAppearance.shadowColor = nil
        navBarAppearance.shadowImage = UIImage()
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.tintColor = .White

        guard let project = project else { return }
        guard !project.applicants.isEmpty else {
            print("No applicants")
            return
        }
        updateData()
    }

    func updateData() {
        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self, let project = self.project else { return }
            let group = DispatchGroup()
            var shouldContinue = true

            group.enter()
            self.firebaseManager.getProject(projectID: project.projectID) { result in
                switch result {
                case .success(let project):
                    self.project = project
                    group.leave()
                case .failure(let err):
                    shouldContinue = false
                    group.leave()
                    group.notify(queue: .main) {
                        self.tableView.endHeaderRefreshing()
                        JProgressHUD.shared.showFailure(view: self.view)
                    }
                }
            }

            group.wait()
            guard shouldContinue else { return }
            group.enter()
            self.firebaseManager.getAllMatchedUsersDetail(usersID: project.applicants) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let applicants):
                    self.applicants = applicants
                    group.leave()
                    group.notify(queue: .main) {
                        self.tableView.endHeaderRefreshing()
                        self.updateDatasource()
                    }
                case .failure(let err):
                    group.leave()
                    group.notify(queue: .main) {
                        self.tableView.endHeaderRefreshing()
                        JProgressHUD.shared.showFailure(text: err.localizedDescription,view: self.view)
                    }
                }
            }
        }
    }

    func getAllApplicants(applicantsID: [UserID]) {
        JProgressHUD.shared.showLoading(view: self.view)
        firebaseManager.getAllMatchedUsersDetail(usersID: applicantsID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let applicants):
                self.applicants = applicants
                self.updateDatasource()
                JProgressHUD.shared.dismiss()
            case .failure(let err):
                JProgressHUD.shared.showFailure(text: err.localizedDescription,view: self.view)
            }
        }
    }

    func createProjectGroup(members: [UserID]) {
        if members.isEmpty {
            let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
            guard let groupCreationVC = chatStoryboard.instantiateViewController(
                withIdentifier: GroupCreationViewController.identifier
            ) as? GroupCreationViewController else {
                fatalError("Cannot create group creation vc")
            }
            groupCreationVC.selectedFriends = []
            self.navigationController?.pushViewController(groupCreationVC, animated: true)
        } else {
            firebaseManager.getAllMatchedUsersDetail(usersID: members) { [weak self] result in
                guard let self = self, let project = self.project else { return }
                switch result {
                case .success(let membersInfo):
                    let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                    guard let groupCreationVC = chatStoryboard.instantiateViewController(
                        withIdentifier: GroupCreationViewController.identifier
                    ) as? GroupCreationViewController else {
                        fatalError("Cannot create group creation vc")
                    }
                    groupCreationVC.selectedFriends = membersInfo
                    groupCreationVC.linkedProject = project
                    groupCreationVC.sourceType = .project
                    self.navigationController?.pushViewController(groupCreationVC, animated: true)
                case .failure(let err):
                    print(err)
                    JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                }
            }
        }
    }

    @objc func backToPreviousPage() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Table View Delegate
extension MyPostsDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .noApplicant, .groupButton:
            return 80
        default:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section.allCases[section]
        if section == .description || section == .applicants {
            return 60
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = Section.allCases[section]
        if section == .description || section == .applicants {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: DetailTitleHeaderView.identifier) as? DetailTitleHeaderView else {
                return nil
            }
            if section == .description {
                headerView.layoutHeaderView(title: Constant.FindIdeas.descriptionSectionTitle)
            } else {
                headerView.layoutHeaderView(title: Constant.FindIdeas.applicantsSectionTitle)
            }
            return headerView
        } else {
            return nil
        }
    }
}

// MARK: - Table View Datasource
extension MyPostsDetailViewController {
    func configureDatasource() {
        // swiftlint:disable line_length
        datasource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            return self?.createCell(tableView: tableView, indexPath: indexPath, item: item)
        }
        updateDatasource()
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func createCell(tableView: UITableView, indexPath: IndexPath, item: Item) -> UITableViewCell {
        switch item {
        case .bigImage(let imageURL):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: BigImageCell.identifier,
                for: indexPath) as? BigImageCell else {
                fatalError("Cannot create big image cell")
            }
            cell.layoutCell(imageURL: imageURL)
            return cell

        case .projectName(let project):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProjectTitleCell.identifier, for: indexPath) as? ProjectTitleCell else {
                fatalError("Cannot create recruiting title cell")
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
                            self.getAllApplicants(applicantsID: project.applicants)
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
                            self.getAllApplicants(applicantsID: project.applicants)
                            JProgressHUD.shared.showSuccess(text: Constant.Personal.removeSuccessfully, view: self.view)
                        case .failure(let err):
                            print(err)
                            JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                        }
                    }
                }
            }
            return cell

        case .recruiting(let project):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProjectItemCell.identifier, for: indexPath) as? ProjectItemCell else {
                fatalError("Cannot create recruiting title cell")
            }
            cell.layoutCellWithPosition(project: project)
            return cell

        case .skills(let project):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProjectItemCell.identifier, for: indexPath) as? ProjectItemCell else {
                fatalError("Cannot create skills cell")
            }
            cell.layoutCellWithSkills(project: project)
            return cell

        case .deadline(let project):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProjectItemCell.identifier, for: indexPath) as? ProjectItemCell else {
                fatalError("Cannot create deadline cell")
            }
            cell.layoutCellWithDeadline(project: project)
            return cell

        case .essentialLocation(let project):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProjectItemCell.identifier, for: indexPath) as? ProjectItemCell else {
                fatalError("Cannot create essential location cell")
            }
            cell.layoutCellWithEssentialLocation(project: project)
            return cell

        case .description(let project):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MultilineCell.identifier, for: indexPath) as? MultilineCell else {
                fatalError("Cannot create multiline cell")
            }
            cell.layoutCell(project: project)
            return cell

        case .applicant(let applicant):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactCell.identifier, for: indexPath
            ) as? ContactCell else {
                fatalError("Cannot create contact cell")
            }
            let isMember = (project!.members.map { $0.id }).contains(applicant.user.id)
            cell.layoutCell(user: applicant.user, from: .myPostApplicant, isMember: isMember)
            cell.tapHandler = { [weak self] in
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                guard let profileVC = personalStoryboard.instantiateViewController(
                    withIdentifier: PersonalProfileViewController.identifier
                ) as? PersonalProfileViewController else {
                    fatalError("Cannot create others profile vc")
                }
                profileVC.userID = applicant.user.id

                self?.navigationController?.pushViewController(profileVC, animated: true)
            }
            cell.messageHandler = { [weak self] in
                self?.firebaseManager.getChatroom(id: applicant.user.id) { [unowned self] result in
                    switch result {
                    case .success(let chatroomID):
                        let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                        guard let chatVC = chatStoryboard.instantiateViewController(
                            withIdentifier: ChatroomViewController.identifier
                        ) as? ChatroomViewController else {
                            fatalError("Cannot create chatroom vc")
                        }
                        chatVC.userData = applicant.user
                        chatVC.chatroomID = chatroomID
                        self?.hidesBottomBarWhenPushed = true
                        DispatchQueue.main.async { [unowned self] in
                            self?.hidesBottomBarWhenPushed = false
                        }
                        self?.navigationController?.pushViewController(chatVC, animated: true)
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            cell.acceptApplicationHandler = { [weak self] user in
                guard let self = self, var project = self.project else { return }
                let alert = UIAlertController(title: "確定要將\(user.name)加入團隊中嗎？", message: nil, preferredStyle: .alert)
                let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                    let newMember = Member(id: user.id, role: "", skills: "")
                    JProgressHUD.shared.showLoading(text: Constant.Common.processing, view: self.view)
                    self.firebaseManager.addNewValueToArray(ref: FirestoreEndpoint.projects.ref.document(project.projectID), field: "members", values: [newMember.toDict]) { result in
                        switch result {
                        case .success:
                            JProgressHUD.shared.showSuccess(view: self.view)
                            project.members.append(newMember)
                            self.updateData()

                            if project.chatroom != nil {
                                let alert = UIAlertController(title: "是否要將\(user.name)加入已綁定的工作群組？", message: nil, preferredStyle: .alert)
                                let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                                    JProgressHUD.shared.showLoading(text: Constant.Common.processing, view: self.view)
                                    let newGroupchatroomMember = ChatroomMember(userID: user.id, currentMemberStatus: .join, currentInoutStatus: .in, lastTimeInChatroom: Date())
                                    self.firebaseManager.addNewGroupChatMembers(chatroomID: project.chatroom!, selectedMembers: [newGroupchatroomMember]) { [weak self] result in
                                        guard let self = self else { return }
                                        switch result {
                                        case .success:
                                            self.updateData()

                                            let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                                            guard let chatroomVC = chatStoryboard.instantiateViewController(
                                                withIdentifier: GroupChatroomViewController.identifier
                                            ) as? GroupChatroomViewController else {
                                                fatalError("Cannot get chatroom vc")
                                            }
                                            chatroomVC.chatroomID = project.chatroom

                                            JProgressHUD.shared.showSuccess(view: self.view) {
                                                self.navigationController?.pushViewController(chatroomVC, animated: true)
                                            }
                                        case .failure(let err):
                                            JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                                        }
                                    }
                                }
                                let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
                                    JProgressHUD.shared.showSuccess(text: "已將\(user.name)加入團隊", view: self.view)
                                }
                                alert.addAction(cancelAction)
                                alert.addAction(yesAction)
                                self.present(alert, animated: true)
                            } else {
                                let alert = UIAlertController(title: "是否要為此專案建立新的工作群組？", message: "將包含新加入的成員在內的所有團隊成員加入群組中", preferredStyle: .alert)
                                let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                                    self.createProjectGroup(members: project.members.map { $0.id! })
                                }
                                let cancelAction = UIAlertAction(title: "Cancel", style: .default)
                                alert.addAction(cancelAction)
                                alert.addAction(yesAction)
                                self.present(alert, animated: true)
                            }
                        case .failure(let err):
                            print(err)
                            JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .default)
                alert.addAction(cancelAction)
                alert.addAction(yesAction)
                self.present(alert, animated: true)
            }
            return cell

        case .noApplicant:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NoApplicantTableViewCell.identifier, for: indexPath) as? NoApplicantTableViewCell else {
                fatalError("Cannot create no applicant cell")
            }
            return cell

        case .groupButton(let project):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: JoinButtonCell.identifier,
                for: indexPath) as? JoinButtonCell else {
                fatalError("Cannot create join button cell")
            }
            cell.layoutCell(type: project.chatroom == nil ? .createProjectGroup : .goToProjectGroup)
            cell.tapHandler = { [weak self] usageType in
                guard let self = self, let project = self.project else { return }
                switch usageType {
                case .createProjectGroup:
                    self.createProjectGroup(members: project.members.map { $0.id! })
                case .goToProjectGroup:
                    let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                    guard let chatroomVC = chatStoryboard.instantiateViewController(
                        withIdentifier: GroupChatroomViewController.identifier
                    ) as? GroupChatroomViewController else {
                        fatalError("Cannot get chatroom vc")
                    }
                    chatroomVC.chatroomID = self.project?.chatroom
                    chatroomVC.sourceType = .project

                    guard let rootVC = self.navigationController?.viewControllers[0] as? PersonalEntryViewController else {
                        fatalError("Cannot create personal entry vc")
                    }
                    guard let projectVC = self.navigationController?.viewControllers[1] as? MyPostsViewController else {
                        fatalError("Cannot create my posts vc")
                    }
                    guard let projectDetailVC = self.navigationController?.viewControllers[2] as? MyPostsDetailViewController else {
                        fatalError("Cannot create my post detail vc")
                    }
                    projectDetailVC.project = self.project
                    self.hidesBottomBarWhenPushed = true
                    self.navigationController?.setViewControllers([rootVC, projectVC, projectDetailVC, chatroomVC], animated: true)
                default:
                    break
                }
            }
            return cell
        }
    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        guard let project = project else {
            fatalError("Didn't get project data")
        }
        if let urlString = project.imageURL {
            snapshot.appendItems([.bigImage(urlString)], toSection: .bigImage)
        }
        snapshot.appendItems([.projectName(project)], toSection: .projectName)
        snapshot.appendItems([.recruiting(project)], toSection: .recruiting)
        snapshot.appendItems([.skills(project)], toSection: .skills)
        snapshot.appendItems([.deadline(project)], toSection: .deadline)
        snapshot.appendItems([.essentialLocation(project)], toSection: .essentialLocation)
        snapshot.appendItems([.description(project)], toSection: .description)
        if !applicants.isEmpty {
            snapshot.appendItems(adjustedApplicants.map { .applicant($0) }, toSection: .applicants)
        } else {
            snapshot.appendItems([.noApplicant], toSection: .noApplicant)
        }
        snapshot.appendItems([.groupButton(project)], toSection: .groupButton)

        datasource.apply(snapshot, animatingDifferences: false)
    }
}
