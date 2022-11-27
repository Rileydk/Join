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
    }

    enum Item: Hashable {
        case bigImage(URLString)
        case projectName(String)
        //        case categories
        case recruiting(Project)
        case skills(Project)
        case deadline(Project)
        case essentialLocation(Project)
        case description(Project)
        //        case group
        //        case location
        case applicant(JUser)
        case noApplicant
    }

    typealias ProjectDetailsDatasource = UITableViewDiffableDataSource<Section, Item>
    private var datasource: ProjectDetailsDatasource!
    let firebaseManager = FirebaseManager.shared
    var project: Project?
    var applicants = [JUser]()

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
            tableView.delegate = self
            configureDatasource()

            tableView.separatorStyle = .none
            tableView.allowsSelection = false
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 80
            if #available(iOS 15, *) {
                tableView.sectionHeaderTopPadding = 0
            }
            tableView.backgroundColor = .White
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let project = project else { return }
        guard !project.applicants.isEmpty else {
            print("No applicants")
            return
        }
        getAllApplicants(applicantsID: project.applicants)
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
}

// MARK: - Table View Delegate
extension MyPostsDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section.allCases[indexPath.section]
        if section == .noApplicant {
            return 80
        } else {
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
        if section == .description || section == .applicants  {
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

        case .projectName(let projectName):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProjectTitleCell.identifier, for: indexPath) as? ProjectTitleCell else {
                fatalError("Cannot create recruiting title cell")
            }
            cell.layoutCell(title: projectName)
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
            cell.layoutCell(user: applicant, from: .myPostApplicant)
            cell.tapHandler = { [weak self] in
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                guard let profileVC = personalStoryboard.instantiateViewController(
                    withIdentifier: PersonalProfileViewController.identifier
                ) as? PersonalProfileViewController else {
                    fatalError("Cannot create others profile vc")
                }
                profileVC.userID = applicant.id

                self?.navigationController?.pushViewController(profileVC, animated: true)
            }
            cell.messageHandler = { [weak self] in
                self?.firebaseManager.getChatroom(id: applicant.id) { [unowned self] result in
                    switch result {
                    case .success(let chatroomID):
                        let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                        guard let chatVC = chatStoryboard.instantiateViewController(
                            withIdentifier: ChatroomViewController.identifier
                        ) as? ChatroomViewController else {
                            fatalError("Cannot create chatroom vc")
                        }
                        chatVC.userData = applicant
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
            return cell

        case .noApplicant:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NoApplicantTableViewCell.identifier, for: indexPath) as? NoApplicantTableViewCell else {
                fatalError("Cannot create no applicant cell")
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
        snapshot.appendItems([.projectName(project.name)], toSection: .projectName)
        snapshot.appendItems([.recruiting(project)], toSection: .recruiting)
        snapshot.appendItems([.skills(project)], toSection: .skills)
        snapshot.appendItems([.deadline(project)], toSection: .deadline)
        snapshot.appendItems([.essentialLocation(project)], toSection: .essentialLocation)
        snapshot.appendItems([.description(project)], toSection: .description)
        if !applicants.isEmpty {
            snapshot.appendItems(applicants.map { .applicant($0) }, toSection: .applicants)
        } else {
            snapshot.appendItems([.noApplicant], toSection: .noApplicant)
        }

        datasource.apply(snapshot, animatingDifferences: false)
    }
}
