//
//  PersonalMainViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit
import FirebaseAuth

class PersonalEntryViewController: UIViewController {
    enum Section: CaseIterable {
        case buttonsGroup
        case goNextPage
        case signout
    }

    enum NextPage: String, CaseIterable {
        case friends = "我的好友"
        case collection = "我的收藏"
        case settings = "個人設定"
    }

    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: PersonalMainThumbnailCell.identifier, bundle: nil),
                forCellReuseIdentifier: PersonalMainThumbnailCell.identifier
            )
            tableView.register(
                UINib(nibName: ButtonsGroupTableViewCell.identifier, bundle: nil),
                forCellReuseIdentifier: ButtonsGroupTableViewCell.identifier)
            tableView.register(
                UINib(nibName: GoNextPageButtonCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoNextPageButtonCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.isScrollEnabled = false
            tableView.separatorStyle = .none
            tableView.allowsSelection = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let navVC = navigationController else { return }
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.White]
        navBarAppearance.backgroundColor = .Blue1
        navBarAppearance.shadowColor = .clear
        navBarAppearance.shadowImage = UIImage()
        navVC.navigationBar.standardAppearance = navBarAppearance
        navVC.navigationBar.scrollEdgeAppearance = navBarAppearance
        navVC.navigationBar.tintColor = .White

        tableView.reloadData()
    }

    let firebaseManager = FirebaseManager.shared
    let appleSignInManager = AppleSignInManager.shared

    func goToNextPage(index: Int) {
        let nextPage = NextPage.allCases[index]
        switch nextPage {
        case .friends:
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let friendsListVC = personalStoryboard.instantiateViewController(
                withIdentifier: UsersListViewController.identifier
                ) as? UsersListViewController else {
                fatalError("Cannot create personal profile vc")
            }
            navigationController?.pushViewController(friendsListVC, animated: true)

        case .collection:
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let myCollectionsVC = personalStoryboard.instantiateViewController(
                withIdentifier: MyRelatedProjectsViewController.identifier
                ) as? MyRelatedProjectsViewController else {
                fatalError("Cannot create personal profile vc")
            }
            myCollectionsVC.projectsType = .collections
            navigationController?.pushViewController(myCollectionsVC, animated: true)
        case .settings:
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let personalSettingsVC = personalStoryboard.instantiateViewController(
                withIdentifier: PersonalSettingsViewController.identifier
                ) as? PersonalSettingsViewController else {
                fatalError("Cannot create personal profile vc")
            }
            hidesBottomBarWhenPushed = true
            DispatchQueue.main.async { [weak self] in
                self?.hidesBottomBarWhenPushed = false
            }
            navigationController?.pushViewController(personalSettingsVC, animated: true)
        }
    }

    func signOut(completion: ((Result<String, Error>) -> Void)? = nil) {
        UserDefaults.standard.clearUserInfo()

        do {
            try firebaseManager.myAuth.signOut()
            completion?(.success("Success"))
        } catch let signOutError as NSError {
            completion?(.failure(signOutError))
        }
    }
}

// MARK: - Table View Delegate
extension PersonalEntryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .buttonsGroup: return 280
        default: return 55
        }
    }
}

// MARK: - Table View Datasource
extension PersonalEntryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Section.allCases[section] == .goNextPage {
            return NextPage.allCases.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .buttonsGroup:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ButtonsGroupTableViewCell.identifier, for: indexPath) as? ButtonsGroupTableViewCell else {
                fatalError("Cannot create buttons group table view cell")
            }
            cell.layoutCell()
            cell.goNextPageHandler = { [weak self] button in
                guard let self = self else { return }
                let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)

                switch button {
                case .profile:
                    guard let profileVC = personalStoryboard.instantiateViewController(
                        withIdentifier: PersonalProfileViewController.identifier
                        ) as? PersonalProfileViewController else {
                        fatalError("Cannot create personal profile vc")
                    }
                    profileVC.userID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)
                    self.hidesBottomBarWhenPushed = true
                    DispatchQueue.main.async { [weak self] in
                        self?.hidesBottomBarWhenPushed = false
                    }
                    self.navigationController?.pushViewController(profileVC, animated: true)
                case .myProject:
                    let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                    guard let myPostsVC = personalStoryboard.instantiateViewController(
                        withIdentifier: MyPostsViewController.identifier
                    ) as? MyPostsViewController else {
                        fatalError("Cannot create personal profile vc")
                    }
                    self.navigationController?.pushViewController(myPostsVC, animated: true)
                case .myApplications:
                    let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                    guard let myApplicationsVC = personalStoryboard.instantiateViewController(
                        withIdentifier: MyRelatedProjectsViewController.identifier
                    ) as? MyRelatedProjectsViewController else {
                        fatalError("Cannot create personal profile vc")
                    }
                    self.navigationController?.pushViewController(myApplicationsVC, animated: true)
                }
            }
            return cell

        case .signout:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GoNextPageButtonCell.identifier,
                for: indexPath) as? GoNextPageButtonCell else {
                fatalError("Cannot create go next page button cell")
            }
            cell.layoutCellForLogout()
            cell.tapHandler = { [weak self] in
                let alert = UIAlertController(title: "確定要登出嗎？", message: nil, preferredStyle: .alert)
                let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                    self?.signOut { result in
                        switch result {
                        case .success:
                            self?.backToRoot()
                        case .failure(let err):
                            print(err)
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alert.addAction(cancelAction)
                alert.addAction(yesAction)
                self?.present(alert, animated: true)
            }
            return cell

        default:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GoNextPageButtonCell.identifier,
                for: indexPath) as? GoNextPageButtonCell else {
                fatalError("Cannot create go next page button cell")
            }
            cell.layoutCell(title: NextPage.allCases[indexPath.row].rawValue)
            cell.tapHandler = { [weak self] in
                self?.goToNextPage(index: indexPath.row)
            }
            return cell
        }
    }
}

extension UIViewController {
    func backToRoot() {
        if let rootVC = view.window?.rootViewController as? MockLoginViewController {
            rootVC.dismiss(animated: false)
        } else {
            // 下一行是假登入用
//            tabBarController?.selectedIndex = 0

            let mainStoryboard = UIStoryboard(name: StoryboardCategory.main.rawValue, bundle: nil)
            guard let loginVC = mainStoryboard.instantiateViewController(
                withIdentifier: LoginViewController.identifier
                ) as? LoginViewController else {
                fatalError("Cannot instantiate log in vc")
            }

            // 下一段是假登入用
//            guard let loginVC = mainStoryboard.instantiateViewController(
//                withIdentifier: MockLoginViewController.identifier
//            ) as? MockLoginViewController else {
//                fatalError("Cannot instantiate log in vc")
//            }

            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: false)
        }
    }
}
