//
//  PersonalMainViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit
import FirebaseAuth
import AuthenticationServices

class PersonalEntryViewController: UIViewController {
    enum Section: CaseIterable {
        case person
        case goNextPage
        case signout
        case deleteAccount
    }

    enum NextPage: String, CaseIterable {
        case profile = "我的主頁"
        case posts = "我的專案"
        case applications = "我的應徵"
        case friends = "我的好友"
        case blockList = "我的黑名單"
        case preference = "個人設定"
        case privacyPolicy = "隱私權政策"
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    let firebaseManager = FirebaseManager.shared
    let appleSignInManager = AppleSignInManager.shared

    func goToNextPage(index: Int) {
        let nextPage = NextPage.allCases[index]
        switch nextPage {
        case .profile:
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let profileVC = personalStoryboard.instantiateViewController(
                withIdentifier: PersonalProfileViewController.identifier
            ) as? PersonalProfileViewController else {
                fatalError("Cannot create personal profile vc")
            }
            profileVC.userID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)
            navigationController?.pushViewController(profileVC, animated: true)

        case .posts:
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let myPostsVC = personalStoryboard.instantiateViewController(
                withIdentifier: MyPostsViewController.identifier
                ) as? MyPostsViewController else {
                fatalError("Cannot create personal profile vc")
            }
            navigationController?.pushViewController(myPostsVC, animated: true)

        case .applications:
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let myApplicationsVC = personalStoryboard.instantiateViewController(
                withIdentifier: MyApplicationsViewController.identifier
                ) as? MyApplicationsViewController else {
                fatalError("Cannot create personal profile vc")
            }
            navigationController?.pushViewController(myApplicationsVC, animated: true)

        case .friends, .blockList:
            let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
            guard let friendsListVC = personalStoryboard.instantiateViewController(
                withIdentifier: UsersListViewController.identifier
                ) as? UsersListViewController else {
                fatalError("Cannot create personal profile vc")
            }
            if nextPage == .blockList {
                friendsListVC.usageType = .blockList
            }
            navigationController?.pushViewController(friendsListVC, animated: true)

        case .privacyPolicy:
            if let url = URL(string: Constant.Link.privacyPolicyURL) {
                UIApplication.shared.open(url)
            }

        case .preference:
            return
        }
    }

    func clearUserDefaults() {
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.uidKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userThumbnailURLKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userNameKey)
        UserDefaults.standard.setValue(nil, forKey: UserDefaults.UserKey.userInterestsKey)
    }

    func signOut(completion: ((Result<String, Error>) -> Void)? = nil) {
        clearUserDefaults()

        do {
            try firebaseManager.myAuth.signOut()
            completion?(.success("Success"))
        } catch let signOutError as NSError {
            completion?(.failure(signOutError))
        }
    }

    func deleteAccount(completion: @escaping (Result<String, Error>) -> Void) {
        let user = Auth.auth().currentUser
        let group = DispatchGroup()
        var shouldContinue = true
        JProgressHUD.shared.showLoading(text: Constant.Alert.longDurationProcess,view: self.view)

        appleSignInManager.appleSignInQueue.async { [weak self] in
            guard let self = self else { return }

            group.enter()
            self.appleSignInManager.revokeCredential { result in
                switch result {
                case .success:
                    group.leave()
                case .failure(let err):
                    shouldContinue = false
                    group.leave()
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                    }
                }
            }

            group.wait()
            guard shouldContinue else { return }
            group.enter()
            self.firebaseManager.clearUserData { result in
                switch result {
                case .success:
                    group.leave()
                case .failure(let err):
                    shouldContinue = false
                    group.leave()
                }
            }

            group.wait()
            group.enter()
            user?.delete { err in
                if let err = err {
                    // TODO: - Reauthenticate
                    shouldContinue = false
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.failure(err))
                    }
                } else {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(.success("Successfully delete"))
                    }
                }
            }
        }
    }

    func alertConfirmation() {
        let alert = UIAlertController(title: "您是否確定要繼續刪除帳號流程？",
                                      message: "您的所有專案、訊息及好友都將被刪除", preferredStyle: .actionSheet)
        let yesAction = UIAlertAction(title: "確定刪除", style: .destructive) {[weak self]  _ in
            guard let self = self else { return }
            JProgressHUD.shared.showLoading(view: self.view)
            self.deleteAccount { result in
                switch result {
                case .success:
                    JProgressHUD.shared.showSuccess(text: "帳號已成功刪除", view: self.view) {
                        self.signOut { [weak self] result in
                            switch result {
                            case .success:
                                self?.backToRoot()
                            case .failure(let err):
                                print(err)
                            }
                        }
                    }
                case .failure(let err):
                    JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "我再想想", style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(yesAction)
        present(alert, animated: true)
    }

    func alertReauthentication() {
        let alert = UIAlertController(title: "是否確定刪除帳號？",
                                      message: "您的所有專案、訊息及好友都將被刪除，未來也無任何方法可取回。\n若您確定要刪除帳號，為確保您的資料不會意外被刪除，會將您自動登出，並請您重新登入以確認您的身份", preferredStyle: .actionSheet)
        let yesAction = UIAlertAction(title: "我要刪除，開始重新登入", style: .destructive) { [weak self]  _ in
            guard let self = self else { return }
            let request = self.appleSignInManager.generateAuthRequest()
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()

        }
        let cancelAction = UIAlertAction(title: "我再想想", style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(yesAction)
        present(alert, animated: true)
    }
}

// MARK: - Table View Delegate
extension PersonalEntryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 190
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
        switch section {
        case .person:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PersonalMainThumbnailCell.identifier,
                for: indexPath) as? PersonalMainThumbnailCell else {
                fatalError("Cannot create person main thumbnail cell")
            }
            cell.layoutCell(isEditing: false)
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

        case .deleteAccount:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GoNextPageButtonCell.identifier,
                for: indexPath) as? GoNextPageButtonCell else {
                fatalError("Cannot create go next page button cell")
            }
            cell.layoutCellForDeleteAccount()
            cell.tapHandler = { [weak self] in
                self?.alertReauthentication()
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

// MARK: - AS Authorization Controller Delegate
extension PersonalEntryViewController: ASAuthorizationControllerDelegate {
    @available(iOS 13, *)
    // swiftlint:disable line_length
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        appleSignInManager.signInApple(authorization: authorization) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.alertConfirmation()
            case .failure(let err):
                JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        JProgressHUD.shared.showFailure(text: error.localizedDescription, view: self.view)
    }
}

// MARK: - AS Authorization Controller Presentation Context Providing
extension PersonalEntryViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        self.view.window!
    }
}
