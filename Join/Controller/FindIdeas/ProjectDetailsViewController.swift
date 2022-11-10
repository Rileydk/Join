//
//  ProjectDetailsViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class ProjectDetailsViewController: BaseViewController {
    enum Section: CaseIterable {
        case bigImage
//        case categories
//        case deadline
//        case essentialLocation
//        case description
//        case group
        case contact
//        case location
        case joinButton
    }

    enum Item: Hashable {
        case bigImage(URLString)
//        case categories
//        case deadline
//        case essentialLocation
//        case description
//        case group
        case contact(User)
//        case location
        case joinButton(Project)
    }

    typealias ProjectDetailsDatasource = UITableViewDiffableDataSource<Section, Item>
    private var datasource: ProjectDetailsDatasource!
    let firebaseManager = FirebaseManager.shared
    var project: Project?
    var userData: User?

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: BigImageCell.identifier, bundle: nil),
                forCellReuseIdentifier: BigImageCell.identifier
            )
            tableView.register(
                UINib(nibName: JoinButtonCell.identifier, bundle: nil),
                forCellReuseIdentifier: JoinButtonCell.identifier
            )
            tableView.register(
                UINib(nibName: ContactCell.identifier, bundle: nil),
                forCellReuseIdentifier: ContactCell.identifier
            )
            tableView.register(
                UINib(nibName: DetailTitleHeaderView.identifier, bundle: nil),
                forHeaderFooterViewReuseIdentifier: DetailTitleHeaderView.identifier
            )
            tableView.sectionHeaderHeight = UITableView.automaticDimension
            tableView.estimatedSectionHeaderHeight = 80
            tableView.delegate = self
            configureDatasource()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let userID = project?.contact {
            firebaseManager.getUserInfo(id: userID) { [weak self] result in
                switch result {
                case .success(let user):
                    self?.userData = user
                    self?.updateDatasource()
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    func checkAlreadyApplied(project: Project) {
        firebaseManager.firebaseQueue.async { [weak self] in
            self?.firebaseManager.getAllApplicants(
                projectID: project.projectID, applicantID: myAccount.id, completion: { [weak self] result in
                switch result {
                case .success(let applicants):
                    if applicants.contains(myAccount.id) {
                        self?.alertAlreadyAppied()
                    } else {
                        self?.alertCheckApplication(project: project)
                    }
                case .failure(let err):
                    print(err)
                }
            })
        }
    }

    func applyForProject(projectID: ProjectID) {
        firebaseManager.applyForProject(projectID: projectID, applicantID: myAccount.id) { result in
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

    func alertAlreadyAppied() {
        let alert = UIAlertController(title: "已經應徵過了", message: "不能重複應徵喔！", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }
}

// MARK: - Table View Delegate
extension ProjectDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 180
        } else {
            return 100
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: DetailTitleHeaderView.identifier) as? DetailTitleHeaderView else {
                return nil
            }
            if let project = project {
                headerView.layoutHeaderView(project: project)
                return headerView
            } else {
                return nil
            }
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
                    withIdentifier: OthersProfileViewController.identifier
                ) as? OthersProfileViewController else {
                    fatalError("Cannot create others profile vc")
                }
                profileVC.userData = self?.userData
                self?.navigationController?.pushViewController(profileVC, animated: true)
            }
            cell.messageHandler = { [weak self] in
                guard let id = self?.userData?.id else { return }
                self?.firebaseManager.getChatroom(id: id) { [unowned self] result in
                    switch result {
                    case .success(let chatroomID):
                        let chatStoryboard = UIStoryboard(name: StoryboardCategory.chat.rawValue, bundle: nil)
                        guard let chatVC = chatStoryboard.instantiateViewController(
                            withIdentifier: ChatroomViewController.identifier
                        ) as? ChatroomViewController else {
                            fatalError("Cannot create chatroom vc")
                        }
                        chatVC.userData = self?.userData
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

        case .joinButton:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: JoinButtonCell.identifier,
                for: indexPath) as? JoinButtonCell else {
                fatalError("Cannot create join button cell")
            }
            cell.joinHandler = { [weak self] in
                guard let project = self?.project else { return }
                self?.checkAlreadyApplied(project: project)

                // 選項暫時只有一人，因此不需要 picker
//                guard let strongSelf = self else { return }
//                let positionPicker = UIPickerView()
//                positionPicker.translatesAutoresizingMaskIntoConstraints = false
//                positionPicker.delegate = self
//                positionPicker.dataSource = self
//                strongSelf.view.addSubview(positionPicker)
//
//                NSLayoutConstraint.activate([
//                    positionPicker.leadingAnchor.constraint(equalTo: strongSelf.view.leadingAnchor),
//                    positionPicker.trailingAnchor.constraint(equalTo: strongSelf.view.trailingAnchor),
//                    positionPicker.bottomAnchor.constraint(equalTo: strongSelf.view.bottomAnchor),
//                    positionPicker.heightAnchor.constraint(equalToConstant: 300)
//                ])
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
        if let userData = userData {
            snapshot.appendItems([.contact(userData)], toSection: .contact)
        }
        if project.contact != myAccount.id {
            snapshot.appendItems([.joinButton(Project.mockProject)], toSection: .joinButton)
        }
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Picker View Delegate
// extension ProjectDetailsViewController: UIPickerViewDelegate {
//
// }

// MARK: - Picker View Datasource
// extension ProjectDetailsViewController: UIPickerViewDataSource {
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        1
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        project?.recruiting.count ?? 0
//    }
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        guard let project = project else { return nil }
//        let item = project.recruiting[component]
//        return item.role
//    }
// }
