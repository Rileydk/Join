//
//  FindPartnersBasicViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class FindPartnersBasicViewController: UIViewController {

    lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var submitButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(goNextPage), for: .touchUpInside)
        return button
    }()

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: SingleLineInputCell.identifier, bundle: nil),
                forCellReuseIdentifier: SingleLineInputCell.identifier
            )
            tableView.register(
                UINib(nibName: MultilineInputCell.identifier, bundle: nil),
                forCellReuseIdentifier: MultilineInputCell.identifier
            )
            tableView.register(
                UINib(nibName: GoCategorySelectionCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoCategorySelectionCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.estimatedRowHeight = UITableView.automaticDimension
            tableView.allowsSelection = false
        }
    }

    var formState = FindPartnersFormSections.basicSection
    var selectedCategories = [String]() {
        didSet {
            tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    func layoutView() {
        title = Tab.findPartners.title
        submitButton.setTitle(formState.buttonTitle, for: .normal)

        if let tabBarView = tabBarController?.view,
           let tabBar = tabBarController?.tabBar {
            tabBarView.addSubview(bottomView)
            bottomView.addSubview(submitButton)

            NSLayoutConstraint.activate([
                bottomView.heightAnchor.constraint(equalToConstant: 80),
                bottomView.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
                bottomView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
                bottomView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
                submitButton.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 20),
                submitButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -20),
                submitButton.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 20)
            ])
        }
    }

    @objc func goNextPage() {

    }

    func goSelectCategories() {
        let selectCategoriesVC = SelectionCategoriesViewController(
            selectedCategories: self.selectedCategories
        )
        selectCategoriesVC.view.backgroundColor = .white
        selectCategoriesVC.modalPresentationStyle = .pageSheet

        if #available(iOS 15.0, *) {
            selectCategoriesVC.sheetPresentationController?.detents = [.medium(), .large()]
            selectCategoriesVC.sheetPresentationController?.prefersGrabberVisible = true
        }

        selectCategoriesVC.passingHandler = { [weak self] newSelectCategories in
            self?.selectedCategories = newSelectCategories
        }

        self.present(selectCategoriesVC, animated: true)
    }
}

// MARK: - Table View Delegate
extension FindPartnersBasicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let inputType = formState.items[indexPath.row].type
        if inputType == .goNextButton {
            return UITableView.automaticDimension
        } else if inputType == .textField {
            return 120
        } else if inputType == .textView {
            return 250
        } else {
            // if inputType == .goNextPage
            return 100
        }
    }
}

// MARK: - Table View Data Source
extension FindPartnersBasicViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        formState.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let inputType = formState.items[indexPath.row].type
        if inputType == .textField {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SingleLineInputCell.identifier,
                for: indexPath) as? SingleLineInputCell else {
                fatalError("Cannot create single line input cell")
            }
            cell.layoutCell(info: formState.items[indexPath.row])
            return cell

        } else if inputType == .textView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MultilineInputCell.identifier,
                for: indexPath) as? MultilineInputCell else {
                fatalError("Cannot create single line input cell")
            }
            cell.layoutCell(info: formState.items[indexPath.row])
            return cell

        } else {
            // if inputType == .goNextPage
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GoCategorySelectionCell.identifier,
                for: indexPath) as? GoCategorySelectionCell else {
                fatalError("Cannot create single line input cell")
            }
            cell.layoutCell(
                info: formState.items[indexPath.row],
                tags: selectedCategories
            )
            cell.tapHandler = { [weak self] in
                self?.goSelectCategories()
            }
            return cell
        }
    }
}
