//
//  PersonalSettingsViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/12/4.
//

import UIKit
import FirebaseAuth
import AuthenticationServices
import SafariServices

class PersonalSettingsViewController: BaseViewController {
    enum Section: String, CaseIterable {
        case accountSettings = "帳號設定"
        case aboutJoin = "關於 Join:找夥伴"

        var rowsTitles: [String] {
            switch self {
            case .accountSettings: return AccountSettings.allCases.map { $0.rawValue }
            case .aboutJoin: return AboutJoin.allCases.map { $0.rawValue }
            }
        }
    }

    enum AccountSettings: String, CaseIterable {
        case blockList = "封鎖名單"
        case deleteAccount = "刪除帳號"
    }

    enum AboutJoin: String, CaseIterable {
        case privacyPolicy = "隱私權政策"
//        case usage = "使用教學"
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: GoNextPageTableViewCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoNextPageTableViewCell.identifier)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.backgroundColor = .Blue1
            tableView.sectionHeaderTopPadding = 0
            tableView.allowsSelection = false
        }
    }

    let appleSignInManager = AppleSignInManager.shared
    let firebaseManager = FirebaseManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "個人設定"
        navigationItem.backButtonDisplayMode = .minimal
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavBarAppearance(to: .dark)
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

    func signOut(completion: ((Result<String, Error>) -> Void)? = nil) {
        UserDefaults.standard.clearUserInfo()

        do {
            try firebaseManager.myAuth.signOut()
            completion?(.success("Success"))
        } catch let signOutError as NSError {
            completion?(.failure(signOutError))
        }
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
}

// MARK: - Table View Delegate
extension PersonalSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.systemFont(ofSize: 15)
        header.textLabel?.textColor = .White
    }
}

// MARK: - Table View Datasource
extension PersonalSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section.allCases[section]
        switch section {
        case .accountSettings: return AccountSettings.allCases.count
        case .aboutJoin: return AboutJoin.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section.allCases[indexPath.section]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GoNextPageTableViewCell.identifier, for: indexPath) as? GoNextPageTableViewCell else {
            fatalError("Cannot create go next page table view cell")
        }
        cell.layoutCell(title: section.rowsTitles[indexPath.row])

        switch section {
        case .accountSettings:
            let row = AccountSettings.allCases[indexPath.row]
            switch row {
            case .blockList:
                cell.tapHandler = { [weak self] in
                    let personalStoryboard = UIStoryboard(name: StoryboardCategory.personal.rawValue, bundle: nil)
                    guard let friendsListVC = personalStoryboard.instantiateViewController(
                        withIdentifier: UsersListViewController.identifier
                    ) as? UsersListViewController else {
                        fatalError("Cannot create personal profile vc")
                    }
                    friendsListVC.usageType = .blockList
                    self?.navigationController?.pushViewController(friendsListVC, animated: true)
                }
            case .deleteAccount:
                cell.tapHandler = { [weak self] in
                    self?.alertReauthentication()
                }
                return cell
            }
        case .aboutJoin:
            let row = AboutJoin.allCases[indexPath.row]
            switch row {
            case .privacyPolicy:
                cell.tapHandler = { [weak self] in
                    if let url = URL(string: Constant.Link.privacyPolicyURL) {
                        let safari = SFSafariViewController(url: url)
                        self?.present(safari, animated: true)
                    }
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section.allCases[section].rawValue
    }
}

// MARK: - AS Authorization Controller Delegate
extension PersonalSettingsViewController: ASAuthorizationControllerDelegate {
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
extension PersonalSettingsViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        self.view.window!
    }
}
