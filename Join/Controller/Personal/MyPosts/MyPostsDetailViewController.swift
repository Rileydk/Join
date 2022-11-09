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
        //        case categories
        //        case deadline
        //        case essentialLocation
        //        case description
        //        case group
        //        case location
        case applicants
    }

    enum Item: Hashable {
        case bigImage(URLString)
        //        case categories
        //        case deadline
        //        case essentialLocation
        //        case description
        //        case group
        //        case location
        case applicant(User)
    }

    typealias ProjectDetailsDatasource = UITableViewDiffableDataSource<Section, Item>
    private var datasource: ProjectDetailsDatasource!
    let firebaseManager = FirebaseManager.shared
    var project: Project?
    var applicants = [User]()

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: BigImageCell.identifier, bundle: nil),
                forCellReuseIdentifier: BigImageCell.identifier
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
        guard let project = project else { return }
        guard !project.applicants.isEmpty else {
            print("No applicants")
            return
        }
        getAllApplicants(applicantsID: project.applicants)
    }

    func getAllApplicants(applicantsID: [UserID]) {
        firebaseManager.getAllMatchedUsersDetail(usersID: applicantsID) { [weak self] result in
            switch result {
            case .success(let applicants):
                self?.applicants = applicants
                self?.updateDatasource()
            case .failure(let err):
                print(err)
            }
        }
    }
}

// MARK: - Table View Delegate
extension MyPostsDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 180
        } else {
            return 100
        }
    }

//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let section = Section.allCases[section]
//        if section ==  {
//            guard let headerView = tableView.dequeueReusableHeaderFooterView(
//                withIdentifier: DetailTitleHeaderView.identifier) as? DetailTitleHeaderView else {
//                return nil
//            }
//            if let project = project {
//                headerView.layoutHeaderView(project: project)
//                return headerView
//            } else {
//                return nil
//            }
//        } else {
//            return nil
//        }
//    }
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
        case .applicant(let applicant):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactCell.identifier, for: indexPath
                ) as? ContactCell else {
                fatalError("Cannot create contact cell")
            }
            cell.layoutCell(user: applicant)
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
        snapshot.appendItems(applicants.map { .applicant($0) }, toSection: .applicants)
        datasource.apply(snapshot, animatingDifferences: false)
    }
}
