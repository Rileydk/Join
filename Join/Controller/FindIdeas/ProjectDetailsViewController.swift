//
//  ProjectDetailsViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class ProjectDetailsViewController: BaseViewController {
    enum SourceType {
        case findIdeas
        case myApplications
    }

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
        case contact
        // case location
        case joinButton
    }

    enum Item: Hashable {
        case bigImage(URLString)
        case projectName(Project)
        // case categories
        case recruiting(Project)
        case skills(Project)
        case deadline(Project)
        case essentialLocation(Project)
        case description(Project)
        // case group
        case contact(JUser)
        // case location
        case joinButton(Project)
    }

    typealias ProjectDetailsDatasource = UITableViewDiffableDataSource<Section, Item>
    private var datasource: ProjectDetailsDatasource!
    let firebaseManager = FirebaseManager.shared
    let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? ""
    var project: Project?
    var userData: JUser?
    var sourceType: SourceType = .findIdeas
    var didTapMessageButton = false

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
                UINib(nibName: JoinButtonCell.identifier, bundle: nil),
                forCellReuseIdentifier: JoinButtonCell.identifier
            )
            tableView.register(
                UINib(nibName: DetailTitleHeaderView.identifier, bundle: nil),
                forHeaderFooterViewReuseIdentifier: DetailTitleHeaderView.identifier
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

        if  let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey),
            let project = project,
            project.contact != myID {
            let button = UIButton()
            let verticalMoreImage = UIImage(
                named: JImages.Icon_24px_VerticalMore.rawValue)?
                .withRenderingMode(.alwaysTemplate)
            button.setImage(verticalMoreImage, for: .normal)
            button.tintColor = .White

            button.showsMenuAsPrimaryAction = true
            let reportAction = UIAction(
                title: Constant.FindIdeas.report,
                attributes: [], state: .off) { [weak self] _ in
                let alert = UIAlertController(
                    title: Constant.FindIdeas.reportAlert,
                    message: nil, preferredStyle: .actionSheet)
                let yesAction = UIAlertAction(
                    title: Constant.Common.confirm,
                    style: .destructive) { [weak self] _ in
                    self?.sendReport()
                }
                let cancelAction = UIAlertAction(title: Constant.Common.cancel, style: .cancel)
                alert.addAction(cancelAction)
                alert.addAction(yesAction)
                self?.present(alert, animated: true)
            }
            let elements: [UIAction] = [reportAction]
            let menu = UIMenu(children: elements)
            button.menu = menu

            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)

        }

        guard let project = project else { return }
        title = project.name

        tableView.addRefreshHeader { [weak self] in
            self?.getContactInfo()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getContactInfo()
        setNavBarAppearance(to: .dark)
        didTapMessageButton = false
    }

    func getContactInfo() {
        if let userID = project?.contact {
            firebaseManager.getUserInfo(id: userID) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let user):
                    self.userData = user
                    self.updateDatasource()
                    self.tableView.endHeaderRefreshing()
                case .failure(let error):
                    print(error)
                    self.tableView.endHeaderRefreshing()
                    JProgressHUD.shared.showFailure(text: error.localizedDescription, view: self.view)
                }
            }
        }
    }

    func checkAlreadyApplied(project: Project) {
        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            self.firebaseManager.getAllApplicants(
                projectID: project.projectID,
                applicantID: self.myID) { result in
                switch result {
                case .success(let applicants):
                    if applicants.contains(self.myID) {
                        self.alertAlreadyApplied()
                    } else {
                        self.alertCheckApplication(project: project)
                    }
                case .failure(let err):
                    print(err)
                }
            }
        }
    }

    func applyForProject(projectID: ProjectID) {
        firebaseManager.applyForProject(projectID: projectID, applicantID: myID) { result in
            switch result {
            case .success:
                print("Success")
            case .failure(let err):
                print(err)
            }
        }
    }

    func alertCheckApplication(project: Project) {
        let alert = UIAlertController(
            title: "確定要應徵\n\"\(project.recruiting[0].role)\"嗎？",
            message: "點擊確定將送出應徵申請", preferredStyle: .alert
        )
        let yesAction = UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            self?.applyForProject(projectID: project.projectID)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(yesAction)
        present(alert, animated: true)
    }

    func alertAlreadyApplied() {
        let alert = UIAlertController(title: "已經應徵過了", message: "不能重複應徵喔！", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }

    func sendReport() {
        guard let project = project else { return }

        JProgressHUD.shared.showLoading(text: Constant.Common.processing, view: self.view)
        let report = Report(
            reportID: "", type: .idea,
            reportedObjectID: project.projectID,
            reportTime: Date(), reason: nil)
        firebaseManager.addNewReport(report: report) { result in
            switch result {
            case .success:
                JProgressHUD.shared.showSuccess(text: Constant.FindIdeas.reportResult, view: self.view)
            case .failure(let err):
                print(err)
                JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
            }
        }
    }
}

// MARK: - Table View Delegate
extension ProjectDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section.allCases[indexPath.section]
        if section == .joinButton {
            return 100
        } else {
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section.allCases[section]
        if section == .description || section == .contact {
            return 60
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = Section.allCases[section]
        if section == .description || section == .contact {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: DetailTitleHeaderView.identifier) as? DetailTitleHeaderView else {
                return nil
            }
            if section == .description {
                headerView.layoutHeaderView(title: Constant.FindIdeas.descriptionSectionTitle)
            } else {
                headerView.layoutHeaderView(title: Constant.FindIdeas.contactSectionTitle)
            }
            return headerView
        } else {
            return nil
        }
    }
}

// MARK: - Table View Datasource
extension ProjectDetailsViewController {
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
                            self.getContactInfo()
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
                            self.getContactInfo()
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

        case .contact(let user):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactCell.identifier,
                for: indexPath) as? ContactCell else {
                fatalError("Cannot create project contact cell")
            }
            cell.layoutCell(user: user, from: .projectDetails)
            cell.tapHandler = { [weak self] in
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                guard let profileVC = personalStoryboard.instantiateViewController(
                    withIdentifier: PersonalProfileViewController.identifier
                ) as? PersonalProfileViewController else {
                    fatalError("Cannot create others profile vc")
                }
                profileVC.userID = self?.userData?.id
                self?.navigationController?.pushViewController(profileVC, animated: true)
            }
            cell.messageHandler = { [weak self] in
                guard let self = self else { return }
                if !self.didTapMessageButton {
                    guard let id = self.userData?.id else { return }
                    self.firebaseManager.getChatroom(id: id) { [unowned self] result in
                        switch result {
                        case .success(let chatroomID):
                            let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                            guard let chatVC = chatStoryboard.instantiateViewController(
                                withIdentifier: ChatroomViewController.identifier
                            ) as? ChatroomViewController else {
                                fatalError("Cannot create chatroom vc")
                            }
                            chatVC.userData = self.userData
                            chatVC.chatroomID = chatroomID
                            self.hidesBottomBarWhenPushed = true
                            DispatchQueue.main.async { [unowned self] in
                                self.hidesBottomBarWhenPushed = false
                            }
                            self.navigationController?.pushViewController(chatVC, animated: true)
                        case .failure(let error):
                            print(error)
                        }
                    }
                    self.didTapMessageButton = true
                }
            }
            navigationItem.backButtonDisplayMode = .minimal

            return cell

        case .joinButton:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: JoinButtonCell.identifier,
                for: indexPath) as? JoinButtonCell else {
                fatalError("Cannot create join button cell")
            }
            cell.layoutCell(type: .joinProject)
            cell.tapHandler = { [weak self] _ in
                guard let project = self?.project else { return }
                self?.checkAlreadyApplied(project: project)
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
        if let userData = userData {
            snapshot.appendItems([.contact(userData)], toSection: .contact)
        }
        if project.contact != myID {
            snapshot.appendItems([.joinButton(Project.mockProject)], toSection: .joinButton)
        }
        datasource.apply(snapshot, animatingDifferences: false)
    }
}
