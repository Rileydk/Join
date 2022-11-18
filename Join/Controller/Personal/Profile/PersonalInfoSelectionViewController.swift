//
//  PersonalInfoSelectionViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit
import JGProgressHUD

class PersonalInfoSelectionViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(UINib(nibName: OneSelectionCell.identifier, bundle: nil),
                               forCellReuseIdentifier: OneSelectionCell.identifier)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.allowsMultipleSelection = true
            tableView.backgroundColor = .Gray5
        }
    }

    let firebaseManager = FirebaseManager.shared
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self, action: #selector(updateInterests))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Discard", style: .plain, target: self, action: #selector(backToPreviousPage))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        JProgressHUD.shared.showLoading(view: self.view)
        firebaseManager.getAllInterests { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let interests):
                self.categories = interests
                JProgressHUD.shared.dismiss()
            case .failure(let err):
                print(err)
                JProgressHUD.shared.showFailure(view: self.view)
            }
        }
    }

    @objc func updateInterests() {
        JProgressHUD.shared.showSaving(view: view)

        firebaseManager.updateMyInterests(interests: selectedCategories) { [weak self] result in
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
        print("selected:", selectedCategories)
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
        cell.layoutCell(interest: item, isSelected: isSelected)
        return cell
    }
}
