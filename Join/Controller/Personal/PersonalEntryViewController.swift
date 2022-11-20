//
//  PersonalMainViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit

class PersonalEntryViewController: UIViewController {
    enum Section: CaseIterable {
        case person
        case goNextPage
        case logout
    }

    enum NextPage: String, CaseIterable {
        case profile = "我的主頁"
        case posts = "我的專案"
        case applications = "我的應徵紀錄"
        case friends = "我的好友"
        case preference = "偏好設定"
    }

    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: PersonalMainThumbnailCell.identifier, bundle: nil),
                forCellReuseIdentifier: PersonalMainThumbnailCell.identifier
            )
            tableView.register(
                UINib(nibName: GoNextPageButtonCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoNextPageButtonCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    let firebaseManager = FirebaseManager.shared

    func goToNextPage(index: Int) {
        if NextPage.allCases[index] == .profile {
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let profileVC = personalStoryboard.instantiateViewController(
                withIdentifier: PersonalProfileViewController.identifier
                ) as? PersonalProfileViewController else {
                fatalError("Cannot create personal profile vc")
            }
            profileVC.userID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)
            navigationController?.pushViewController(profileVC, animated: true)
        }

        if NextPage.allCases[index] == .posts {
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let myPostsVC = personalStoryboard.instantiateViewController(
                withIdentifier: MyPostsViewController.identifier
            ) as? MyPostsViewController else {
                fatalError("Cannot create personal profile vc")
            }
            navigationController?.pushViewController(myPostsVC, animated: true)
        }

        if NextPage.allCases[index] == .applications {
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let myApplicationsVC = personalStoryboard.instantiateViewController(
                withIdentifier: MyApplicationsViewController.identifier
            ) as? MyApplicationsViewController else {
                fatalError("Cannot create personal profile vc")
            }
            navigationController?.pushViewController(myApplicationsVC, animated: true)
        }

        if NextPage.allCases[index] == .friends {
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let friendsListVC = personalStoryboard.instantiateViewController(
                withIdentifier: FriendsListViewController.identifier
            ) as? FriendsListViewController else {
                fatalError("Cannot create personal profile vc")
            }
            navigationController?.pushViewController(friendsListVC, animated: true)
        }
    }

    func signOut(completion: @escaping (Result<String, Error>) -> Void) {
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.uidKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userThumbnailURLKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userNameKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userInterestsKey)
        completion(.success("Successfully signed out"))
        print("signed out:", UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey))

//        do {
//            try firebaseManager.myAuth.signOut()
//            completion(.success("Success"))
//        } catch let signOutError as NSError {
//            completion(.failure(signOutError))
//        }
    }
}

// MARK: - Table View Delegate
extension PersonalEntryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 210
        } else {
            return 60
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
        if section == .person {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PersonalMainThumbnailCell.identifier,
                for: indexPath) as? PersonalMainThumbnailCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.layoutCell(isEditing: false)
            return cell
        } else if section == .logout {
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
        } else {
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
            tabBarController?.selectedIndex = 0

            let mainStoryboard = UIStoryboard(name: StoryboardCategory.main.rawValue, bundle: nil)
//            guard let loginVC = mainStoryboard.instantiateViewController(
//                withIdentifier: LoginViewController.identifier
//                ) as? LoginViewController else {
//                fatalError("Cannot instantiate log in vc")
//            }
            guard let loginVC = mainStoryboard.instantiateViewController(
                withIdentifier: MockLoginViewController.identifier
            ) as? MockLoginViewController else {
                fatalError("Cannot instantiate log in vc")
            }
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: false)
        }
    }
}
