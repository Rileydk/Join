//
//  MemberCardViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

protocol MemberCardDelegate: AnyObject {
    func memberCardViewController(_ controller: MemberCardViewController, didSetMembers members: [Member])
    // swiftlint:disable line_length
    func  memberCardViewController(_ controller: MemberCardViewController, didSetRecruiting recruiting: [OpenPosition])
}

class MemberCardViewController: BaseViewController {

    enum `Type` {
        case member
        case recruiting
    }
    weak var delegate: MemberCardDelegate?

    var type: `Type` = .member
    var members = [Member(id: "", name: "", role: "", skills: "")]
    var recruiting = [OpenPosition(role: "", skills: "", number: "1")]
    var firstTimeLoad = true

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: AddNewCell.identifier, bundle: nil),
                forCellReuseIdentifier: AddNewCell.identifier
            )
            tableView.register(DropdownEmptyAlertCell.self, forCellReuseIdentifier: DropdownEmptyAlertCell.identifier)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.memberCardViewController(self, didSetRecruiting: recruiting)
    }

    func layoutView() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: FindPartnersFormSections.memberBranchButtonTitle,
            style: .done, target: self,
            action: #selector(backToPreviousPage)
        )
    }

    @objc func backToPreviousPage() {
        if type == .member {
            for index in stride(from: members.count - 1, through: 0, by: -1) {
                // 若有某些欄位沒填寫，但不是全部沒填寫（全部沒填寫者就幫 user 刪除）
                // 但先不刪除，直到確定跳頁再刪除
                let member = members[index]
                if (member.id == nil || member.role.isEmpty || member.skills.isEmpty) &&
                    !(member.id == nil && member.role.isEmpty && member.skills.isEmpty) {
                    if member.id == nil {
                        alertUserFriendWrong()
                    } else {
                        alertUserToFillColumns()
                    }
                    return

                } else {
                    if (member.id == nil && member.role.isEmpty && member.skills.isEmpty) {
                        members.remove(at: index)
                    }
                }
            }
            delegate?.memberCardViewController(self, didSetMembers: members)

        } else if type == .recruiting {
            for index in stride(from: recruiting.count - 1, through: 0, by: -1) {
                // 若有某些欄位沒填寫，但不是全部沒填寫（全部沒填寫者就幫 user 刪除）(recruiting的人數預設為 1，因此略過不檢查)
                // 但先不刪除，直到確定跳頁再刪除
                let position = recruiting[index]
                if (position.role.isEmpty || position.number.isEmpty || position.skills.isEmpty) &&
                    !(position.role.isEmpty && position.skills.isEmpty) {
                    alertUserToFillColumns()
                    return

                } else {
                    if (position.role.isEmpty && position.skills.isEmpty) {
                        recruiting.remove(at: index)
                    }
                }
            }
            delegate?.memberCardViewController(self, didSetRecruiting: recruiting)
        }
        navigationController?.popViewController(animated: true)
    }

    func alertUserToFillColumns() {
        let alert = UIAlertController(title: FindPartnersFormSections.memeberCardNotFilledAlertTitle, message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: FindPartnersFormSections.alertActionTitle, style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }

    func alertUserFriendWrong() {
        let alert = UIAlertController(title: FindPartnersFormSections.friendColumnWrongAlertTitle, message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: FindPartnersFormSections.alertActionTitle, style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }
}

// MARK: - Table View Delegate
extension MemberCardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if type == .member && indexPath.row <= members.count - 1 {
            return 200
        } else if type == .recruiting && indexPath.row <= recruiting.count - 1 {
            return 200
        } else {
            return 45
        }
    }
}

// MARK: - Table View Data Source
extension MemberCardViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if type == .member {
            return members.count + 1
        } else if type == .recruiting {
            return recruiting.count + 1
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if type == .member && indexPath.row <= members.count - 1 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MemberCell.identifier,
                for: indexPath) as? MemberCell else {
                fatalError("Cannot create MemberCell")
            }
            cell.layoutCell(info: members[indexPath.row])
            cell.delegate = self
            cell.deleteHandler = { [weak self] in
                self?.recruiting.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
            }
            return cell

        } else if type == .recruiting && indexPath.row <= recruiting.count - 1 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RecruitingCell.identifier,
                for: indexPath) as? RecruitingCell else {
                fatalError("Cannot create Recruiting Cell")
            }
            cell.layoutCell(info: recruiting[indexPath.row])
            cell.delegate = self
            cell.deleteHandler = { [weak self] in
                self?.recruiting.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
            }
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddNewCell.identifier,
                for: indexPath) as? AddNewCell else {
                fatalError("Cannot create Add New Cell")
            }
            cell.tapHandler = { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.type == .member {
                    strongSelf.members.append(
                        Member(id: "", name: "", role: "", skills: "")
                    )
                } else if strongSelf.type == .recruiting {
                    strongSelf.recruiting.append(
                        OpenPosition(role: "", skills: "", number: "1")
                    )
                }
                tableView.reloadData()
            }
            return cell
        }
    }
}

// MARK: - Recruiting Cell Delegate
extension MemberCardViewController: RecruitingCellDelegate {
    func cell(_ recruitingCell: RecruitingCell, didSet newRecruit: OpenPosition) {
        let index = tableView.indexPath(for: recruitingCell)!.row
        recruiting[index] = newRecruit
    }
}

// MARK: - Member Cell Delegate
extension MemberCardViewController: MemberCellDelegate {
    func cell(_ memberCell: MemberCell, didSet newMember: Member) {
        let index = tableView.indexPath(for: memberCell)!.row
        members[index] = newMember
    }
}
