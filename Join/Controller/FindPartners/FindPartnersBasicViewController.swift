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
    var image: UIImage? {
        didSet {
            checkCanGoNextPage()
        }
    }
    var formState = FindPartnersFormSections.basicSection
    var selectedCategories = [String]() {
        didSet {
            if tableView != nil {
                tableView.reloadData()
            }
            checkCanGoNextPage()
        }
    }
    var position = OpenPosition(role: "", skills: "", number: "1") {
        didSet {
            checkCanGoNextPage()
        }
    }
    var members = [JUser]() {
        didSet {
            if tableView != nil {
                tableView.reloadData()
            }
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
                UINib(nibName: TextFieldComboAmountFieldCell.identifier, bundle: nil),
                forCellReuseIdentifier: TextFieldComboAmountFieldCell.identifier)
            tableView.register(
                UINib(nibName: GoSelectionCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoSelectionCell.identifier
            )
            tableView.register(
                UINib(nibName: FriendCell.identifier, bundle: nil),
                forCellReuseIdentifier: FriendCell.identifier)
            tableView.register(
                UINib(nibName: DatePickerCell.identifier, bundle: nil),
                forCellReuseIdentifier: DatePickerCell.identifier)
            tableView.register(
                UINib(nibName: ProjectCategoryListCell.identifier, bundle: nil),
                forCellReuseIdentifier: ProjectCategoryListCell.identifier)
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
        if formState == FindPartnersFormSections.basicSection {
            navigationItem.title = "\(Tab.findPartners.title) (1/3)"
        } else if formState == FindPartnersFormSections.groupSection {
            navigationItem.title = "\(Tab.findPartners.title) (2/3)"
        } else if formState == FindPartnersFormSections.detailSection {
            navigationItem.title = "\(Tab.findPartners.title) (3/3)"
        }
        tableView.backgroundColor = .White

        let config = UIButton.Configuration.filled()
        rightBarButton = PillButton(configuration: config)
        rightBarButton!.setTitle(formState.buttonTitle, for: .normal)
        rightBarButton!.addTarget(self, action: #selector(goNextPage), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton!)
        checkCanGoNextPage()

        if formState == FindPartnersFormSections.groupSection ||
           formState == FindPartnersFormSections.detailSection {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(
                    named: JImages.Icons_24px_Back.rawValue),
                    style: .plain, target: self, action: #selector(backToPreviousPage))
        }
    }

    func checkCanGoNextPage() {
        if formState == FindPartnersFormSections.basicSection &&
            (project.name.isEmpty || project.description.isEmpty || selectedCategories.isEmpty) {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if formState == FindPartnersFormSections.groupSection &&
                    (position.role.isEmpty || position.number.isEmpty || position.skills.isEmpty) {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if formState == FindPartnersFormSections.detailSection &&
                    (project.deadline == nil || project.location.isEmpty || image == nil) {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    @objc func goNextPage() {
        if formState == FindPartnersFormSections.basicSection {
            project.categories = selectedCategories
            project.recruiting = [position]
            let findPartnersStoryboard = UIStoryboard(
                name: StoryboardCategory.findPartners.rawValue, bundle: nil
            )
            guard let nextVC = findPartnersStoryboard.instantiateViewController(
                identifier: FindPartnersBasicViewController.identifier
            ) as? FindPartnersBasicViewController else {
                fatalError("Cannot load FindPartnersBasicVC from storyboard.")
            }
            nextVC.project = project
            nextVC.position = position
            nextVC.members = members
            nextVC.formState = FindPartnersFormSections.groupSection
            nextVC.view.backgroundColor = .white
            navigationController?.pushViewController(nextVC, animated: true)

        } else if formState == FindPartnersFormSections.groupSection {
            project.recruiting = [position]
            project.members = members.map { Member(id: $0.id, role: "empty", skills: "empty") }
            let findPartnersStoryboard = UIStoryboard(
                name: StoryboardCategory.findPartners.rawValue, bundle: nil
            )
            guard let nextVC = findPartnersStoryboard.instantiateViewController(
                identifier: FindPartnersBasicViewController.identifier
            ) as? FindPartnersBasicViewController else {
                fatalError("Cannot load FindPartnersBasicVC from storyboard.")
            }
            nextVC.project = project
            nextVC.position = position
            nextVC.members = members
            nextVC.formState = FindPartnersFormSections.detailSection
            nextVC.view.backgroundColor = .white
            navigationController?.pushViewController(nextVC, animated: true)

        } else if formState == FindPartnersFormSections.detailSection {
            post()
        }
    }
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

    func goSelectGroupMembers() {
        let chatroomStoryboard = UIStoryboard(
            name: StoryboardCategory.chat.rawValue, bundle: nil)
        guard let friendSelectionVC = chatroomStoryboard.instantiateViewController(
            withIdentifier: FriendSelectionViewController.identifier
            ) as? FriendSelectionViewController else {
            fatalError("Cannot load friend selection vc")
        }
        friendSelectionVC.source = .addMembersToFindPartners
        friendSelectionVC.selectedFriends = members
        friendSelectionVC.addToFindPartnersHandler = { [weak self] groupMembers in
            self?.members = groupMembers
        }
        navigationController?.pushViewController(friendSelectionVC, animated: true)
    }

    func alertDeadlineError() {
        let alert = UIAlertController(
            title: FindPartnersFormSections.findPartnersNotFilledAlertTitle,
            message: nil, preferredStyle: .alert
        )
        let action = UIAlertAction(title: FindPartnersFormSections.alertActionTitle, style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }

    func post() {
        JProgressHUD.shared.showLoading(text: "Posting", view: self.view)

        firebaseManager.postNewProject(project: project, image: image) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                JProgressHUD.shared.showSuccess(view: self.view) {
                    let findPartnerStoryboard = UIStoryboard(name: StoryboardCategory.findPartners.rawValue, bundle: nil)
                    guard let basicVC = findPartnerStoryboard.instantiateViewController(
                        withIdentifier: FindPartnersBasicViewController.identifier
                        ) as? FindPartnersBasicViewController else {
                        fatalError("Cannot load find partners basic vc basic part")
                    }
                    self.navigationController?.setViewControllers([basicVC], animated: false)
                    basicVC.tabBarController?.selectedIndex = 0
                }
            case .failure(let err):
                JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
            }
        }
    }

    @objc func backToPreviousPage() {
        guard let basicVC = navigationController?.viewControllers.dropLast().first as? FindPartnersBasicViewController,
            basicVC.formState == FindPartnersFormSections.basicSection else {
            fatalError("Cannot load find partners basic vc basic part")
        }
        basicVC.project = project
        basicVC.position = position
        basicVC.members = members
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Table View Delegate
extension FindPartnersBasicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < formState.items.count {
            let inputType = formState.items[indexPath.row].type
            switch inputType {
            case .textField: return 112
            case .textView: return 242
            case .textFieldComboAmountPicker: return 112
            case .goNextButton: return 118
            case .datePicker: return 120
            case .uploadImage: return 300
            default: return 100
            }
        } else {
            if formState == FindPartnersFormSections.basicSection {
                // basic 中的 category cell
                return 44
            } else {
                // if formState == FindPartnersFormSections.groupSection
                return 70
            }
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

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if formState == FindPartnersFormSections.basicSection {
                selectedCategories.remove(at: indexPath.row - 3)
            }
            if formState == FindPartnersFormSections.groupSection {
                members.remove(at: indexPath.row - 3)
            }
        }
    }
}

// MARK: - Table View Data Source
extension FindPartnersBasicViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if formState == FindPartnersFormSections.basicSection {
            return formState.items.count + selectedCategories.count
        } else if formState == FindPartnersFormSections.groupSection {
            return formState.items.count + members.count
        } else {
            // if formState == FindPartnersFormSections.detailSection
            return formState.items.count
        }
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
                    cell.layoutCell(withTitle: .projectName, value: project.name)

                    cell.updateProjectName = { [weak self] projectName in
                        self?.project.name = projectName
                    }
                }
                if formState == FindPartnersFormSections.detailSection {
                    print("project location:", project.location)
                    cell.layoutCell(withTitle: .location, value: project.location)
                    cell.updateLocation = { [weak self] location in
                        self?.project.location = location
                    }
                }
                return cell

            } else if inputType == .textView {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: MultilineInputCell.identifier,
                    for: indexPath) as? MultilineInputCell else {
                    fatalError("Cannot create single line input cell")
                }
                if formState == FindPartnersFormSections.basicSection {
                    cell.sourceType = .findPartnersDescription
                    cell.layoutCellForFindPartner(
                        title: formState.items[indexPath.row].name,
                        value: project.description,
                        shouldFill: formState.items[indexPath.row].must
                    )
                }
                if formState == FindPartnersFormSections.groupSection {
                    cell.sourceType = .findPartnersSkill
                    cell.layoutCellForFindPartner(
                        title: formState.items[indexPath.row].name,
                        value: position.skills.isEmpty ?  "" : position.skills,
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
            } else if inputType == .goNextButton && formState == FindPartnersFormSections.groupSection {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: GoSelectionCell.identifier,
                    for: indexPath) as? GoSelectionCell else {
                    fatalError("Cannot create single line input cell")
                }
                cell.layoutCell(info: formState.items[indexPath.row])
                cell.tapHandler = { [weak self] in
                    self?.goSelectGroupMembers()
                }
                return cell
//            } else if inputType == .goNextButton &&
//                formState.items[indexPath.row].name == FindPartnersFormSections.detailSection.items[1].name {
//                guard let cell = tableView.dequeueReusableCell(
//                    withIdentifier: GoSelectionCell.identifier,
//                    for: indexPath) as? GoSelectionCell else {
//                    fatalError("Cannot create single line input cell")
//                }
//                cell.layoutCellWithTextField(info: formState.items[indexPath.row])
//                cell.delegate = self
//                return cell

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
            } else if inputType == .textFieldComboAmountPicker {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: TextFieldComboAmountFieldCell.identifier, for: indexPath
                    ) as? TextFieldComboAmountFieldCell else {
                    fatalError("Cannot create text field combo amount picker cell")
                }

                cell.layoutCell(
                    longFieldTitle: Constant.FindPartners.recruitingFieldTitle,
                    longFieldValue: position.role,
                    shortFieldTitle: Constant.FindPartners.recruitingNumberFieldTitle,
                    shortFieldValue: position.number
                )
                cell.updateRecruitingRole = { [weak self] role in
                    self?.position.role = role.trimmingCharacters(in: .whitespaces)
                }
                cell.updateRecruitingNumber = { [weak self] number in
                    self?.position.number = number
                }
                return cell
            } else if inputType == .datePicker {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: DatePickerCell.identifier, for: indexPath) as? DatePickerCell else {
                    fatalError("Cannot create date picker cell")
                }
                print("project deadline:", project.deadline)
                cell.layoutCell(item: formState.items[indexPath.row], deadline: project.deadline)
                project.deadline = cell.datePicker.date
                cell.updateDateHandler = { [weak self] deadline in
                    self?.project.deadline = deadline
                }
                return cell
            } else {
                fatalError("Shouldn't have this type")
            }
        } else {
            if formState == FindPartnersFormSections.basicSection {
                // basic 中的 category cell
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: ProjectCategoryListCell.identifier, for: indexPath
                ) as? ProjectCategoryListCell else {
                    fatalError("Cannot load One Selection Cell")
                }
                cell.layoutCell(content: selectedCategories[indexPath.row - 3])
                return cell
            } else {
                // if formState == FindPartnersFormSections.groupSection
                let member = members[indexPath.row - 3]
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: FriendCell.identifier, for: indexPath
                ) as? FriendCell else {
                    fatalError("Cannot create friend cell")
                }
                cell.layoutCell(friend: member, source: .projectGroupMemberSelection)
                cell.contentView.backgroundColor = .White
                return cell
            }
        }
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

        if textView.contentType == .userInput {
            if formState == FindPartnersFormSections.basicSection {
                project.description = textView.text.replacingOccurrences(of: "\\s+$", with: "",
                                                                         options: .regularExpression)
            }
            if formState == FindPartnersFormSections.groupSection {
                position.skills = textView.text.replacingOccurrences(of: "\\s+$", with: "",
                                                                     options: .regularExpression)
            }
        }

        if textView.text.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression).isEmpty {
            textView.contentType = .placeholder
            if formState == FindPartnersFormSections.basicSection {
                textView.text = Constant.FindPartners.projectDescription
            }
            if formState == FindPartnersFormSections.groupSection {
                textView.text = Constant.FindPartners.recruitingSkillsPlaceholder
            }
            textView.textColor = UIColor.Gray3!.withAlphaComponent(0.7)
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

// MARK: - Image Picker Cell Delegate
extension FindPartnersBasicViewController: ImagePickerCellDelegate {
    func imagePickerCell(_ cell: ImagePickerCell, didSetImage image: UIImage) {
        self.image = image
    }
}
