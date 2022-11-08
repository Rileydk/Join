//
//  MemberCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

protocol MemberCellDelegate: AnyObject {
    func cell(_ memberCell: MemberCell, didSet newMember: Member)
}

class MemberCell: TableViewCell {
    @IBOutlet var friendNameTextField: UITextField!
    @IBOutlet var roleTextField: UITextField!
    @IBOutlet var skillTextField: UITextField!

    let dropDownTableView = UITableView()
    let dropDownAlertTableView = UITableView()
    let dropDownCellHeight: CGFloat = 70

    let firebaseManager = FirebaseManager.shared
    var deleteHandler: (() -> Void)?
    weak var delegate: MemberCellDelegate?

    var friends = [User]()
    var filteredFriends = [User]()
    var member = Member(id: nil, name: "", role: "", skills: "")

    override func awakeFromNib() {
        dropDownTableView.register(
            UINib(nibName: FriendCell.identifier, bundle: nil),
            forCellReuseIdentifier: FriendCell.identifier
        )
        dropDownAlertTableView.register(
            UINib(nibName: DropdownEmptyAlertCell.identifier, bundle: nil),
            forCellReuseIdentifier: DropdownEmptyAlertCell.identifier
        )
        dropDownTableView.delegate = self
        dropDownTableView.dataSource = self
        dropDownTableView.layer.borderWidth = 1
        dropDownTableView.layer.borderColor = UIColor.lightGray.cgColor

        dropDownAlertTableView.delegate = self
        dropDownAlertTableView.dataSource = self
        dropDownAlertTableView.layer.borderWidth = 1
        dropDownAlertTableView.layer.borderColor = UIColor.lightGray.cgColor
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeDropDownTableView()
    }

    func layoutCell(info: Member) {
        friendNameTextField.text = info.id
        roleTextField.text = info.role
        var skills = ""
        skillTextField.text = info.skills

        friendNameTextField.addTarget(self, action: #selector(textFieldDidChanged), for: .editingChanged)
        roleTextField.addTarget(self, action: #selector(textFieldDidChanged), for: .editingChanged)
        skillTextField.addTarget(self, action: #selector(textFieldDidChanged), for: .editingChanged)

        firebaseManager.getAllFriendsInfo { [unowned self] result in
            switch result {
            case .success(let friends):
                self.friends = friends
                self.filteredFriends = friends
            case .failure(let error):
                print(error)
            }
        }
    }

    func addDropDownTableView(frame: CGRect) {
        dropDownTableView.frame = CGRect(
            x: frame.origin.x + 30, y: frame.maxY + 15,
            width: 170, height: 0
        )
        dropDownTableView.layer.cornerRadius = 5
        contentView.addSubview(dropDownTableView)
        dropDownTableView.reloadData()

        let cellAmount = filteredFriends.count < 5
            ? filteredFriends.count
            : 5

        UIView.animate(
            withDuration: 0.4, delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.dropDownTableView.frame = CGRect(
                    x: frame.origin.x + 30, y: frame.maxY + 15,
                    width: 170, height: CGFloat(
                        self.dropDownCellHeight * CGFloat(cellAmount)
                    )
                )
            }
        )
    }

    func removeDropDownTableView() {
        let frame = friendNameTextField.frame
        UIView.animate(
            withDuration: 0.4, delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.dropDownTableView.frame = CGRect(
                    x: frame.origin.x + 30, y: frame.maxY + 15,
                    width: 170, height: 0
                )
            }
        )
    }

    func addDropDownAlert(frame: CGRect) {
        dropDownAlertTableView.frame = CGRect(
            x: frame.origin.x + 30, y: frame.maxY + 15,
            width: 170, height: 0
        )
        dropDownAlertTableView.layer.cornerRadius = 5
        contentView.addSubview(dropDownAlertTableView)
        dropDownAlertTableView.reloadData()

        UIView.animate(
            withDuration: 0.4, delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.dropDownAlertTableView.frame = CGRect(
                    x: frame.origin.x + 30, y: frame.maxY + 15,
                    width: 170, height: CGFloat(
                        self.dropDownCellHeight
                    )
                )
            }
        )
    }

    func removeDropDownAlert() {
        let frame = friendNameTextField.frame
        UIView.animate(
            withDuration: 0.4, delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.dropDownAlertTableView.frame = CGRect(
                    x: frame.origin.x + 30, y: frame.maxY + 15,
                    width: 170, height: 0
                )
            }
        )
    }

    @objc func textFieldDidChanged(_ sender: UITextField) {
        if sender == friendNameTextField {
            let searchText = sender.text?.trimmingCharacters(in: .whitespaces)
            if let searchText = searchText, !searchText.isEmpty {
                filteredFriends = friends.filter { $0.name.localizedStandardContains(searchText) }
                if !filteredFriends.isEmpty {
                    removeDropDownAlert()
                    addDropDownTableView(frame: friendNameTextField.frame)
                } else {
                    removeDropDownTableView()
                    addDropDownAlert(frame: friendNameTextField.frame)
                }
            } else {
                removeDropDownTableView()
                removeDropDownAlert()
                filteredFriends = friends
            }
        } else {
            member.role = roleTextField.text ?? ""
            member.skills = skillTextField.text ?? ""
            delegate?.cell(self, didSet: member)
        }
    }

    @IBAction func deleteCard() {
        deleteHandler?()
    }
}

// MARK: - Table View Delegate
extension MemberCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        dropDownCellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !filteredFriends.isEmpty {
            friendNameTextField.text = filteredFriends[indexPath.row].name
            member.id = filteredFriends[indexPath.row].id
            member.name = filteredFriends[indexPath.row].name
            removeDropDownTableView()
            delegate?.cell(self, didSet: member)
        }
    }
}

// MARK: - Table View Datasource
extension MemberCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == dropDownTableView {
            return filteredFriends.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == dropDownTableView {
            let friend = filteredFriends[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: FriendCell.identifier, for: indexPath
            ) as? FriendCell else {
                fatalError("Cannot create friend cell")
            }
            cell.layoutCell(friend: friend)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: DropdownEmptyAlertCell.identifier, for: indexPath
                ) as? DropdownEmptyAlertCell else {
                fatalError("Cannot create alert cell")
            }
            return cell
        }
    }
}
