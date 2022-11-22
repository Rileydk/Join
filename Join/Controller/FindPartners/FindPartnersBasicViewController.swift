//
//  FindPartnersBasicViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit
import FirebaseAuth

class FindPartnersBasicViewController: BaseViewController {
    var rightBarButton: PillButton?

    let firebaseManager = FirebaseManager.shared
    var project = Project(contact: UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey) ?? "") {
        didSet {
            checkCanGoNextPage()
        }
    }
    var image: UIImage?
    var formState = FindPartnersFormSections.basicSection
    var selectedCategories = [String]() {
        didSet {
            tableView.reloadData()
        }
    }

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
                UINib(nibName: ProjectCategoryListCell.identifier, bundle: nil),
                forCellReuseIdentifier: ProjectCategoryListCell.identifier)
            tableView.register(
                UINib(nibName: AddNewLineSectionCell.identifier, bundle: nil),
                forCellReuseIdentifier: AddNewLineSectionCell.identifier
            )
            tableView.register(
                UINib(nibName: ImagePickerCell.identifier, bundle: nil),
                forCellReuseIdentifier: ImagePickerCell.identifier
            )
            tableView.register(
                UINib(nibName: TableViewSimpleHeaderView.identifier, bundle: nil),
                forHeaderFooterViewReuseIdentifier: TableViewSimpleHeaderView.identifier)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.estimatedRowHeight = UITableView.automaticDimension
            tableView.allowsSelection = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func layoutView() {
        title = Tab.findPartners.title
        tableView.backgroundColor = .White

        let config = UIButton.Configuration.filled()
        rightBarButton = PillButton(configuration: config)
        rightBarButton!.setTitle(formState.buttonTitle, for: .normal)
        rightBarButton!.addTarget(self, action: #selector(goNextPage), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton!)
        checkCanGoNextPage()

        if formState == FindPartnersFormSections.groupSection {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(named: JImages.Icons_24px_Back.rawValue), style: .plain, target: self, action: #selector(backToPreviousPage))
        }
    }

    func checkCanGoNextPage() {
        if formState == FindPartnersFormSections.basicSection && (project.name.isEmpty || project.description.isEmpty || project.categories.isEmpty) {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if formState == FindPartnersFormSections.groupSection,
                  project.recruiting.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if formState == FindPartnersFormSections.groupSection,
                  project.recruiting.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    @objc func goNextPage() {
        if formState == FindPartnersFormSections.basicSection {
            project.categories = selectedCategories
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

        } else if formState == FindPartnersFormSections.groupSection {
            let findPartnersStoryboard = UIStoryboard(
                name: StoryboardCategory.findPartners.rawValue, bundle: nil
            )
            guard let nextVC = findPartnersStoryboard.instantiateViewController(
                identifier: FindPartnersBasicViewController.identifier
            ) as? FindPartnersBasicViewController else {
                fatalError("Cannot load FindPartnersBasicVC from storyboard.")
            }
            nextVC.project = project
            nextVC.formState = FindPartnersFormSections.detailSection
            nextVC.view.backgroundColor = .white
            navigationController?.pushViewController(nextVC, animated: true)

        } else if formState == FindPartnersFormSections.detailSection,
                  project.deadline != nil && !project.location.isEmpty {
            post()

        }
    }

//    func alertUserToFillColumns() {
//        let alert = UIAlertController(
//            title: FindPartnersFormSections.findPartnersNotFilledAlertTitle,
//            message: nil, preferredStyle: .alert
//        )
//        let action = UIAlertAction(title: FindPartnersFormSections.alertActionTitle, style: .default)
//        alert.addAction(action)
//        present(alert, animated: true)
//    }

    func goSelectCategories() {
        let personalStoryboard = UIStoryboard(
            name: StoryboardCategory.personal.rawValue, bundle: nil)
        guard let personalInfoSelectionVC = personalStoryboard.instantiateViewController(
            withIdentifier: PersonalInfoSelectionViewController.identifier
        ) as? PersonalInfoSelectionViewController else {
            fatalError("Cannot load PersonalInfoSelectionViewController")
        }
        personalInfoSelectionVC.sourceType = .postCategories
        personalInfoSelectionVC.type = .interests
        personalInfoSelectionVC.selectedCategories = self.selectedCategories
        personalInfoSelectionVC.passingHandler = { [weak self] selectedCategories in
            self?.selectedCategories = selectedCategories
            self?.project.categories = selectedCategories
        }
        navigationController?.pushViewController(personalInfoSelectionVC, animated: true)
    }

    func post() {
        firebaseManager.postNewProject(project: project, image: image) { [weak self] result in
            switch result {
            case .success:
                // FIXME: - 順序不對，應該要在showSucceed結束後再跳轉
                // FIXME: - 頁面沒有被清空
                self?.tabBarController?.selectedIndex = 0
            case .failure(let error):
                print(error)
            }
        }
    }

    @objc func backToPreviousPage() {
        if formState == FindPartnersFormSections.groupSection {
            guard let basicVC = navigationController?.viewControllers.dropLast().first as? FindPartnersBasicViewController,
                basicVC.formState == FindPartnersFormSections.basicSection else {
                fatalError("Cannot load find partners basic vc basic part")
            }
            basicVC.project = project
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - Table View Delegate
extension FindPartnersBasicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < formState.items.count {
            let inputType = formState.items[indexPath.row].type
            if inputType == .goNextButton {
                return 80
            } else if inputType == .addButton {
                return UITableView.automaticDimension
            } else if inputType == .textField {
                return 120
            } else if inputType == .textView {
                return 300
            } else if inputType == .uploadImage {
                return 300
            } else {
                return 100
            }
        } else {
            // basic 中的 category cell
            return 44
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: TableViewSimpleHeaderView.identifier
            ) as? TableViewSimpleHeaderView else {
            fatalError("Cannot load Table View Simple Header View")
        }
        header.titleLabel.text = formState.title
        return header
    }
}

// MARK: - Table View Data Source
extension FindPartnersBasicViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        formState.items.count + selectedCategories.count
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < formState.items.count {
            let inputType = formState.items[indexPath.row].type
            if inputType == .textField {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: SingleLineInputCell.identifier,
                    for: indexPath) as? SingleLineInputCell else {
                    fatalError("Cannot create single line input cell")
                }
                if formState == FindPartnersFormSections.basicSection {
                    cell.layoutCell(withTitle: .projectName, value: "請輸入專案名稱")
                } else {
                    cell.layoutCell(withTitle: .projectName, value: "")
                }
                cell.updateProjectName = { [weak self] projectName in
                    self?.project.name = projectName
                }
                return cell

            } else if inputType == .textView {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: MultilineInputCell.identifier,
                    for: indexPath) as? MultilineInputCell else {
                    fatalError("Cannot create single line input cell")
                }
                if formState == FindPartnersFormSections.basicSection {
                    cell.layoutCellForFindPartnerProjectDescription(
                        title: formState.items[indexPath.row].name,
                        value: project.description,
                        shouldFill: formState.items[indexPath.row].must
                    )
                }
                cell.textView.delegate = self
                return cell

            } else if inputType == .goNextButton && formState == FindPartnersFormSections.basicSection {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: GoSelectionCell.identifier,
                    for: indexPath) as? GoSelectionCell else {
                    fatalError("Cannot create single line input cell")
                }
                cell.layoutCell(info: formState.items[indexPath.row])
                cell.tapHandler = { [weak self] in
                    self?.goSelectCategories()
                }
                return cell

            } else if inputType == .goNextButton &&
                formState.items[indexPath.row].name == FindPartnersFormSections.detailSection.items[0].name {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: GoSelectionCell.identifier,
                    for: indexPath) as? GoSelectionCell else {
                    fatalError("Cannot create single line input cell")
                }
                cell.layoutCellWithDatePicker(info: formState.items[indexPath.row])
                cell.delegate = self
                return cell

            } else if inputType == .goNextButton &&
                formState.items[indexPath.row].name == FindPartnersFormSections.detailSection.items[1].name {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: GoSelectionCell.identifier,
                    for: indexPath) as? GoSelectionCell else {
                    fatalError("Cannot create single line input cell")
                }
                cell.layoutCellWithTextField(info: formState.items[indexPath.row])
                cell.delegate = self
                return cell

            } else if inputType == .addButton {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: AddNewLineSectionCell.identifier,
                    for: indexPath) as? AddNewLineSectionCell else {
                    fatalError("Cannot create add new line cell")
                }

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
                memberVC.title = title
                memberVC.delegate = self

                if title == membersTitle {
                    cell.layoutCell(info: formState.items[indexPath.row], members: project.members)
                    cell.tapHandler = { [weak self] in
                        memberVC.type = .member
                        self?.navigationController?.pushViewController(memberVC, animated: true)
                    }
                } else if title == recruitingTitle {
                    cell.layoutCell(info: formState.items[indexPath.row], recruiting: project.recruiting)
                    cell.tapHandler = { [weak self] in
                        memberVC.type = .recruiting
                        self?.navigationController?.pushViewController(memberVC, animated: true)
                    }
                }

                return cell

            } else if inputType == .uploadImage {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: ImagePickerCell.identifier,
                    for: indexPath) as? ImagePickerCell else {
                    fatalError("Cannot create add image picker cell")
                }
                cell.layoutCell(info: formState.items[indexPath.row])
                cell.delegate = self
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

            } else {
                fatalError("Shouldn't have this type")
            }
        } else {
            // basic 中的 category cell
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ProjectCategoryListCell.identifier, for: indexPath
                ) as? ProjectCategoryListCell else {
                fatalError("Cannot load One Selection Cell")
            }
            cell.layoutCell(content: selectedCategories[indexPath.row - 3])
            return cell
        }
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
    func textViewDidBeginEditing(_ textView: UITextView) {
        guard let textView = textView as? PaddingableTextView else {
            return
        }
        if textView.contentType == .placeholder {
            textView.text = nil
            textView.textColor = .Gray2
            textView.contentType = .userInput
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let textView = textView as? PaddingableTextView else {
            return
        }
        if textView.text.isEmpty {
            textView.contentType = .placeholder
            if formState == FindPartnersFormSections.basicSection {
                textView.text = Constant.FindPartners.projectDescription
            }
            textView.textColor = UIColor.Gray3!.withAlphaComponent(0.7)
        }

        if textView.contentType == .userInput {
            project.description = textView.text
        }
    }
}

// MARK: - Member Card Delegate
extension FindPartnersBasicViewController: MemberCardDelegate {
    func memberCardViewController(_ controller: MemberCardViewController, didSetMembers members: [Member]) {
        project.members = members
    }

    // swiftlint:disable line_length
    func memberCardViewController(_ controller: MemberCardViewController, didSetRecruiting recruiting: [OpenPosition]) {
        project.recruiting = recruiting
    }
}

// MARK: - Go Selection Cell Delegate
extension FindPartnersBasicViewController: GoSelectionCellDelegate {
    func cell(_ cell: GoSelectionCell, didSetDate date: Date) {
        // project.deadline = date.millisecondsSince1970
        project.deadline = date
    }

    func cell(_ cell: GoSelectionCell, didSetLocation location: String) {
        project.location = location
    }
}

// MARK: - Image Picker Cell Delegate
extension FindPartnersBasicViewController: ImagePickerCellDelegate {
    func imagePickerCell(_ cell: ImagePickerCell, didSetImage image: UIImage) {
        self.image = image
    }
}
