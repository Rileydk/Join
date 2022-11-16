//
//  PersonalProfileEditViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/15.
//

import UIKit
import ProgressHUD

class PersonalProfileEditViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(UINib(nibName: PersonalMainThumbnailCell.identifier, bundle: nil),
                               forCellReuseIdentifier: PersonalMainThumbnailCell.identifier)
            tableView.register(UINib(nibName: SingleLineInputCell.identifier, bundle: nil),
                               forCellReuseIdentifier: SingleLineInputCell.identifier)
            tableView.register(UINib(nibName: GoNextPageButtonCell.identifier, bundle: nil),
                               forCellReuseIdentifier: GoNextPageButtonCell.identifier)
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    let firebaseManager = FirebaseManager.shared
    var user: JUser?
    var oldUserInfo: JUser?
    var newImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, target: self, action: #selector(saveToAccount))
        oldUserInfo = user
    }

    @objc func saveToAccount() {
        guard var user = user else {
            print("No user data")
            return
        }

        if !(user.name.isEmpty || user.email.isEmpty) {
            firebaseManager.firebaseQueue.async { [weak self] in
                let group = DispatchGroup()
                if let newImageData = self?.newImage?.jpeg(.lowest) {
                    group.enter()
                    self?.firebaseManager.uploadImage(image: newImageData) { result in
                        switch result {
                        case .success(let imageURL):
                            user.thumbnailURL = imageURL
                            group.leave()
                        case .failure(let err):
                            group.leave()
                            group.notify(queue: .main) {
                                ProgressHUD.showError()
                            }
                        }
                    }
                } else {
                    group.enter()
                    user.thumbnailURL = "\(FindPartnersFormSections.placeholderImageURL)"
                    group.leave()
                }

                group.enter()
                guard let oldInfo = self?.oldUserInfo else { return }
                self?.firebaseManager.updateAuthentication(oldInfo: oldInfo, newInfo: user) { result in
                    switch result {
                    case .success:
                        group.leave()
                    case .failure(let err):
                        group.leave()
                        group.notify(queue: .main) {
                            print(err)
                        }
                    }
                }

                group.wait()
                group.enter()
                self?.firebaseManager.set(user: user) { result in
                    switch result {
                    case .success:
                        group.leave()
                        group.notify(queue: .main) {
                            ProgressHUD.showSucceed()
                            let mainStoryboard = UIStoryboard(name: StoryboardCategory.main.rawValue, bundle: nil)
                            guard let tabBarController = mainStoryboard.instantiateViewController(
                                withIdentifier: TabBarController.identifier
                                ) as? TabBarController else {
                                fatalError("Cannot load tab bar controller")
                            }
                            tabBarController.selectedIndex = 0
                            tabBarController.modalPresentationStyle = .fullScreen
                            self?.present(tabBarController, animated: true)
                        }
                    case .failure(let err):
                        group.leave()
                        group.notify(queue: .main) {
                            ProgressHUD.showError()
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
        4
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 250
        } else if indexPath.section == 1 {
            return 80
        } else {
            return 40
        }
    }
}

// MARK: - Table View Datasource
extension PersonalProfileEditViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let user = user else {
            fatalError("Didn't get user info")
        }
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: PersonalMainThumbnailCell.identifier,
                for: indexPath) as? PersonalMainThumbnailCell else {
                fatalError("Cannot create personal main thumbnail cell")
            }
            cell.layoutCell(user: user, isEditing: true)
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
        } else if indexPath.section == 1 {
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
        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GoNextPageButtonCell.identifier,
                for: indexPath) as? GoNextPageButtonCell else {
                fatalError("Cannot create personal main thumbnail cell")
            }
            if indexPath.section == 2 {
                cell.layoutCell(title: "Edit Skills")
            }
            if indexPath.section == 3 {
                cell.layoutCell(title: "Edit Interests")
            }
            return cell
        }
    }
}
