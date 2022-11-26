//
//  PersonalProfileEditViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/15.
//

import UIKit

class PersonalProfileEditViewController: BaseViewController {
    enum Section: CaseIterable {
        case thumbnail
        case basic
        case introduction
        case skills
        case interests
        case portfolio
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: PersonalMainThumbnailCell.identifier, bundle: nil),
                forCellReuseIdentifier: PersonalMainThumbnailCell.identifier)
            tableView.register(
                UINib(nibName: SingleLineInputCell.identifier, bundle: nil),
                forCellReuseIdentifier: SingleLineInputCell.identifier)
            tableView.register(
                UINib(nibName: MultilineInputCell.identifier, bundle: nil),
                forCellReuseIdentifier: MultilineInputCell.identifier)
            tableView.register(
                UINib(nibName: GoNextPageCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoNextPageCell.identifier)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
        }
    }

    let firebaseManager = FirebaseManager.shared
    var user: JUser? {
        didSet {
            if tableView != nil {
                tableView.reloadData()
            }
        }
    }
    var oldUserInfo: JUser?
    var newImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, target: self, action: #selector(saveToAccount))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) else {
            fatalError("Doesn't have my id")
        }
        JProgressHUD.shared.showLoading(view: view)
        firebaseManager.getUserInfo(id: myID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                self.user = user
                self.oldUserInfo = user
                JProgressHUD.shared.dismiss()
            case .failure(let err):
                JProgressHUD.shared.showFailure(view: self.view)
                print(err)
            }
        }
    }

    @objc func saveToAccount() {
        guard var user = user else {
            print("No user data")
            return
        }

        if !(user.name.isEmpty || user.email.isEmpty) {
            JProgressHUD.shared.showSaving(view: self.view)

            firebaseManager.firebaseQueue.async { [weak self] in
                guard let self = self else { return }
                var shouldContinue = true

                let group = DispatchGroup()
                if let newImageData = self.newImage?.jpeg(.lowest) {
                    group.enter()
                    self.firebaseManager.uploadImage(image: newImageData) { result in
                        switch result {
                        case .success(let imageURL):
                            user.thumbnailURL = imageURL
                            group.leave()
                        case .failure(let err):
                            group.leave()
                            group.notify(queue: .main) {
                                JProgressHUD.shared.showFailure(
                                    text: err.localizedDescription,view: self.view)
                                shouldContinue = false
                            }
                        }
                    }
                } else {
                    group.enter()
                    user.thumbnailURL = "\(FindPartnersFormSections.placeholderImageURL)"
                    group.leave()
                }

                group.enter()
                guard let oldInfo = self.oldUserInfo else { return }
                self.firebaseManager.updateAuthentication(oldInfo: oldInfo, newInfo: user) { result in
                    switch result {
                    case .success:
                        group.leave()
                    case .failure(let err):
                        group.leave()
                        group.notify(queue: .main) {
                            JProgressHUD.shared.showFailure(
                                text: err.localizedDescription,view: self.view)
                            shouldContinue = false
                        }
                    }
                }

                group.wait()
                group.enter()
                self.firebaseManager.set(user: user) { result in
                    switch result {
                    case .success:
                        group.leave()
                        group.notify(queue: .main) {
                            UserDefaults.standard.setUserBasicInfo(user: user)
                            JProgressHUD.shared.showSuccess(view: self.view) {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    case .failure(let err):
                        group.leave()
                        group.notify(queue: .main) {
                            JProgressHUD.shared.showFailure(
                                text: err.localizedDescription,view: self.view)
                            shouldContinue = false
                        }
                    }
                }
            }
        } else {
            let alert = UIAlertController(title: "姓名和Email是必填欄位喔", message: nil, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default)
            alert.addAction(action)
            present(alert, animated: true)
        }
    }
}

// MARK: - Table View Delegate
extension PersonalProfileEditViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard user != nil else { return 0 }
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section.allCases[indexPath.section]
        if section == .thumbnail {
            return 180
        } else if section == .basic {
            return 90
        } else if section == .introduction {
            return 160
        } else {
            return 50
        }
    }
}

// MARK: - Table View Datasource
extension PersonalProfileEditViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section.allCases[section]
        if section == .basic {
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let user = user else {
            fatalError("Didn't get user info")
        }
        let section = Section.allCases[indexPath.section]
        if section == .thumbnail {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PersonalMainThumbnailCell.identifier,
                for: indexPath) as? PersonalMainThumbnailCell else {
                fatalError("Cannot create personal main thumbnail cell")
            }
            cell.layoutCell(isEditing: true)
            cell.updateImage = { [weak self] image in
                self?.newImage = image
            }
            cell.alertPresentHandler = { [weak self] alert in
                self?.present(alert, animated: true)
            }
            cell.cameraPresentHandler = { [weak self] controller in
                self?.present(controller, animated: true)
            }
            cell.libraryPresentHandler = { [weak self] picker in
                self?.present(picker, animated: true)
            }
            return cell

        } else if section == .basic {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SingleLineInputCell.identifier,
                for: indexPath) as? SingleLineInputCell else {
                fatalError("Cannot create personal main thumbnail cell")
            }
            if indexPath.row == 0 {
                cell.layoutCell(withTitle: .name, value: user.name)
                cell.updateName = { [weak self] name in
                    self?.user?.name = name
                }
            }
            if indexPath.row == 1 {
                cell.layoutCell(withTitle: .email, value: user.email)
                cell.updateEmail = { [weak self] email in
                    self?.user?.email = email
                }
            }
            return cell

        } else if section == .introduction {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MultilineInputCell.identifier,
                for: indexPath) as? MultilineInputCell else {
                fatalError("Cannot create personal main thumbnail cell")
            }
            cell.sourceType = .personalEditIntroduction
            cell.layoutCellForEditProfile(introduction: user.introduction ?? "")
            cell.textView.delegate = self
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GoNextPageCell.identifier,
                for: indexPath) as? GoNextPageCell else {
                fatalError("Cannot create personal main thumbnail cell")
            }
            if section == .skills {
                cell.layoutCell(title: Constant.Edit.editSkills)
                cell.tapHandler = { [weak self] in
                    guard let self = self, let skills = self.user?.skills else {
                        fatalError("Cannot get skills")
                    }
                    let personalStoryboard = UIStoryboard(
                        name: StoryboardCategory.personal.rawValue, bundle: nil)
                    guard let personalInfoSelectionVC = personalStoryboard.instantiateViewController(
                        withIdentifier: PersonalInfoSelectionViewController.identifier
                    ) as? PersonalInfoSelectionViewController else {
                        fatalError("Cannot load PersonalInfoSelectionViewController")
                    }
                    personalInfoSelectionVC.type = .skills
                    personalInfoSelectionVC.selectedCategories = skills
                    self.navigationController?.pushViewController(personalInfoSelectionVC, animated: true)
                }
            }

            if section == .interests {
                cell.layoutCell(title: Constant.Edit.editInterests)
                cell.tapHandler = { [weak self] in
                    guard let self = self, let interests = self.user?.interests else {
                        fatalError("Cannot get interests")
                    }
                    let personalStoryboard = UIStoryboard(
                        name: StoryboardCategory.personal.rawValue, bundle: nil)
                    guard let personalInfoSelectionVC = personalStoryboard.instantiateViewController(
                        withIdentifier: PersonalInfoSelectionViewController.identifier
                    ) as? PersonalInfoSelectionViewController else {
                        fatalError("Cannot load PersonalInfoSelectionViewController")
                    }
                    personalInfoSelectionVC.type = .interests
                    personalInfoSelectionVC.selectedCategories = interests
                    self.navigationController?.pushViewController(personalInfoSelectionVC, animated: true)
                }
            }

            if section == .portfolio {
                cell.layoutCell(title: Constant.Edit.addPortfolio)
                cell.tapHandler = { [weak self] in
                    guard let self = self else { return }
                    let personalStoryboard = UIStoryboard(
                        name: StoryboardCategory.personal.rawValue, bundle: nil)
                    guard let addPortfolioVC = personalStoryboard.instantiateViewController(
                        withIdentifier: AddPortfolioViewController.identifier
                    ) as? AddPortfolioViewController else {
                        fatalError("Cannot load AddPortfolioViewController")
                    }
                    self.navigationController?.pushViewController(addPortfolioVC, animated: true)
                }
            }
            return cell
        }
    }
}

// MARK: - Text View Delegate
extension PersonalProfileEditViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        user?.introduction = textView.text
    }
}
