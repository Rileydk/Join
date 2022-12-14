//
//  PersonalInfoSelectionViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit
import JGProgressHUD

enum InfoType: String {
    case skills
    case interests
}

class PersonalInfoSelectionViewController: BaseViewController {
    enum SourceType {
        case personalInfo
        case postCategories
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(UINib(nibName: OneSelectionCell.identifier, bundle: nil),
                               forCellReuseIdentifier: OneSelectionCell.identifier)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.allowsMultipleSelection = true
            tableView.backgroundColor = .Gray6
        }
    }

    let firebaseManager = FirebaseManager.shared
    var sourceType: SourceType = .personalInfo
    var passingHandler: (([String]) -> Void)?
    var type: InfoType = .skills
    var categories = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    var selectedCategories = [String]() {
        didSet {
            title = "已選取\(selectedCategories.count)個類別"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let config = UIButton.Configuration.filled()
        let rightBarButton = PillButton(configuration: config)
        rightBarButton.isEnabled = true
        rightBarButton.setTitle(Constant.Common.save, for: .normal)
        rightBarButton.addTarget(self, action: #selector(tapSave), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: JImages.Icon_24px_Close.rawValue), style: .plain,
            target: self, action: #selector(backToPreviousPage))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        JProgressHUD.shared.showLoading(view: self.view)
        firebaseManager.getPersonalInfo(of: type) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let allCategories):
                self.categories = allCategories
                JProgressHUD.shared.dismiss()
            case .failure(let err):
                print(err)
                JProgressHUD.shared.showFailure(view: self.view)
            }
        }
    }

    @objc func tapSave() {
        if sourceType == .personalInfo {
            updatePersonalInfo()
        } else {
            saveProjectCategories()
        }
    }

    func updatePersonalInfo() {
        JProgressHUD.shared.showSaving(view: view)

        firebaseManager.updatePersonalInfo(of: type, info: selectedCategories) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                JProgressHUD.shared.showSuccess(view: self.view) {
                    self.backToPreviousPage()
                }
            case .failure(let err):
                JProgressHUD.shared.showFailure(view: self.view) {
                    self.backToPreviousPage()
                }
                print(err)
            }
        }
    }

    func saveProjectCategories() {
        JProgressHUD.shared.showSaving(view: self.view)
        passingHandler?(selectedCategories)
        JProgressHUD.shared.showSuccess(view: self.view) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    @objc func backToPreviousPage() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Table View Delegate
extension PersonalInfoSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? OneSelectionCell else {
            fatalError("Cannot get one selection cell")
        }
        if let index = selectedCategories.firstIndex(of: categories[indexPath.row]) {
            selectedCategories.remove(at: index)
            cell.selectImageView.image = UIImage(systemName: "checkmark.circle")
        } else {
            selectedCategories.append(categories[indexPath.row])
            cell .selectImageView.image = UIImage(systemName: "checkmark.circle.fill")
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - Table View Datasource
extension PersonalInfoSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = categories[indexPath.row]
        let isSelected = selectedCategories.contains(item)
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OneSelectionCell.identifier, for: indexPath)
            as? OneSelectionCell else {
            fatalError("Cannot load one selection cell")
        }
        cell.layoutCell(info: item, isSelected: isSelected)
        return cell
    }
}
