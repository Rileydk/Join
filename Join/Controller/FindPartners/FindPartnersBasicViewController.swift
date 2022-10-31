//
//  FindPartnersBasicViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class FindPartnersBasicViewController: UIViewController {
    static let identifier = String(describing: FindPartnersBasicViewController.self)

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
                UINib(nibName: GoSelectionCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoSelectionCell.identifier
            )
            tableView.register(
                UINib(nibName: AddNewLineSectionCell.identifier, bundle: nil),
                forCellReuseIdentifier: AddNewLineSectionCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.estimatedRowHeight = UITableView.automaticDimension
            tableView.allowsSelection = false
        }
    }

    var project = Project()
    var formState = FindPartnersFormSections.basicSection
    var selectedCategories = [String]() {
        didSet {
            print("categories", selectedCategories)
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
        project.categories = selectedCategories
        if formState == FindPartnersFormSections.basicSection {
            if !(project.name.isEmpty || project.description.isEmpty || project.categories.isEmpty) {
                let findPartnersStoryboard = UIStoryboard(
                    name: StoryboardCategory.findPartners.rawValue, bundle: nil
                )
                guard let nextVC = findPartnersStoryboard.instantiateViewController(
                    identifier: FindPartnersBasicViewController.identifier
                    ) as? FindPartnersBasicViewController else {
                    fatalError("Cannot load FindPartnersBasicVC from storyboard.")
                }
                nextVC.project = project
                nextVC.formState = FindPartnersFormSections.groupSection
                nextVC.view.backgroundColor = .white
                navigationController?.pushViewController(nextVC, animated: true)

            } else {
                alertUserToFillColumns()
            }
        }
    }

    func alertUserToFillColumns() {
        let alert = UIAlertController(title: "所有必填欄位都要填喔", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
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
        if inputType == .addButton {
            return UITableView.automaticDimension
        } else if inputType == .textField {
            return 120
        } else if inputType == .textView {
            return 250
        } else if inputType == .goNextButton {
            // 使用 TTGTag 似乎無法用 automaticDimension 推開 cell
            return 200
        } else {
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
        // TODO: - 有沒有辦法用 Protocol 簡化 cell 的 deque 過程？
        let inputType = formState.items[indexPath.row].type
        if inputType == .textField {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SingleLineInputCell.identifier,
                for: indexPath) as? SingleLineInputCell else {
                fatalError("Cannot create single line input cell")
            }
            cell.layoutCell(info: formState.items[indexPath.row])
            cell.textField.delegate = self
            return cell

        } else if inputType == .textView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MultilineInputCell.identifier,
                for: indexPath) as? MultilineInputCell else {
                fatalError("Cannot create single line input cell")
            }
            cell.layoutCell(info: formState.items[indexPath.row])
            cell.textView.delegate = self
            return cell

        } else if inputType == .goNextButton {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GoSelectionCell.identifier,
                for: indexPath) as? GoSelectionCell else {
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

        } else if inputType == .addButton {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddNewLineSectionCell.identifier,
                for: indexPath) as? AddNewLineSectionCell else {
                fatalError("Cannot create add new line cell")
            }
            cell.layoutCell(info: formState.items[indexPath.row])

            let findPartnersStoryboard = UIStoryboard(
                name: StoryboardCategory.findPartners.rawValue,
                bundle: nil
            )

            let membersTitle = FindPartnersFormSections.groupSection.items[0].name
            let recruitingTitle = FindPartnersFormSections.groupSection.items[1].name
            let title = formState.items[indexPath.row].name

            guard let memberVC = findPartnersStoryboard.instantiateViewController(
                withIdentifier: MemberCardViewController.identifier
            ) as? MemberCardViewController else {
                fatalError("Cannot load member card VC from storyboard")
            }

            if title == membersTitle {
                cell.tapHandler = { [weak self] in
                    memberVC.type = .member
                    self?.present(memberVC, animated: true)
                }
            } else if title == recruitingTitle {
                cell.tapHandler = { [weak self] in
                    memberVC.type = .recruiting
                    self?.present(memberVC, animated: true)
                }
            }

            return cell
        } else {
            fatalError("Should not come here")
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        formState.title
    }
}

// MARK: - Text Field Delegate
extension FindPartnersBasicViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        project.name = textField.text ?? ""
    }
}

// MARK: - Text View Delegate
extension FindPartnersBasicViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        project.description = textView.text
    }
}
