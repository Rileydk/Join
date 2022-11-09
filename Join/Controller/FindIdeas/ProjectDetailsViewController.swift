//
//  ProjectDetailsViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class ProjectDetailsViewController: UIViewController {
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
                UINib(nibName: ProjectContactCell.identifier, bundle: nil),
                forCellReuseIdentifier: ProjectContactCell.identifier
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
                withIdentifier: ProjectContactCell.identifier,
                for: indexPath) as? ProjectContactCell else {
                fatalError("Cannot create project contact cell")
            }
            cell.layoutCell(user: user)
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
                // TODO: - 新增假貼文，包含不是好友的，並比對興趣的正確性
                // TODO: - recommendataion 點進去後資料錯誤（應該是資料源用到下面的）
                // TODO: - 若只有一個選項，直接跳出 alert
                // TODO: - 若不只一個選項，選中後，跳出 alert
                // TODO: - 確認後，送出申請，儲存到 Applicant
                guard let strongSelf = self else { return }
                let positionPicker = UIPickerView()
                positionPicker.translatesAutoresizingMaskIntoConstraints = false
                positionPicker.delegate = self
                positionPicker.dataSource = self
                strongSelf.view.addSubview(positionPicker)

                NSLayoutConstraint.activate([
                    positionPicker.leadingAnchor.constraint(equalTo: strongSelf.view.leadingAnchor),
                    positionPicker.trailingAnchor.constraint(equalTo: strongSelf.view.trailingAnchor),
                    positionPicker.bottomAnchor.constraint(equalTo: strongSelf.view.bottomAnchor),
                    positionPicker.heightAnchor.constraint(equalToConstant: 300)
                ])
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

        snapshot.appendItems([.joinButton(Project.mockProject)], toSection: .joinButton)
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Picker View Delegate
extension ProjectDetailsViewController: UIPickerViewDelegate {

}

// MARK: - Picker View Datasource
extension ProjectDetailsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        project?.recruiting.count ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let project = project else { return nil }
        let item = project.recruiting[component]
        print(item)
        return item.role
    }
}
