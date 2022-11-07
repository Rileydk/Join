//
//  MemberCell.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

class MemberCell: TableViewCell {
    @IBOutlet var friendNameTextField: UITextField!
    @IBOutlet var roleTextField: UITextField!
    @IBOutlet var skillTextField: UITextField!

    let dimmedView = UIView()
    let dropDownTableView = UITableView()
    let dropDownCellHeight: CGFloat = 70

    let firebaseManager = FirebaseManager.shared
    var deleteHandler: (() -> Void)?

    var friends = [User]()
    var filteredFriends = [User]()

    override func awakeFromNib() {
        dropDownTableView.register(
            UINib(nibName: FriendCell.identifier, bundle: nil),
            forCellReuseIdentifier: FriendCell.identifier
        )
        dropDownTableView.delegate = self
        dropDownTableView.dataSource = self
        dropDownTableView.layer.borderWidth = 1
        dropDownTableView.layer.borderColor = UIColor.lightGray.cgColor
    }

    func layoutCell(info: Member) {
        friendNameTextField.text = info.id
        roleTextField.text = info.role
        skillTextField.text = info.skills

        firebaseManager.getAllFriendsInfo { [unowned self] result in
            switch result {
            case .success(let friends):
                self.friends = friends
                self.filteredFriends = friends
                addDropDownTableView(frame: friendNameTextField.frame)
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
                self.dimmedView.alpha = 0.5
                self.dropDownTableView.frame = CGRect(
                    x: frame.origin.x + 30, y: frame.maxY + 15,
                    width: 170, height: CGFloat(
                        self.dropDownCellHeight * CGFloat(cellAmount)
                    )
                )
            }
        )
    }

    @objc func removeDropDownTableView() {

    }

    @IBAction func editing(_ sender: UITextField) {

    }

    @IBAction func deleteCard() {

    }
}

// MARK: - Table View Delegate
extension MemberCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        dropDownCellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

// MARK: - Table View Datasource
extension MemberCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredFriends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = filteredFriends[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FriendCell.identifier, for: indexPath
            ) as? FriendCell else {
            fatalError("Cannot create friend cell")
        }
        cell.layoutCell(friend: friend)
        return cell
    }
}
