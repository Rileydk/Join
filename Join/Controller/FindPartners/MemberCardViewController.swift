//
//  MemberCardViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

class MemberCardViewController: UIViewController {

    // TODO: - 控制鍵盤開啟狀態不能滑掉？

    enum `Type` {
        case member
        case recruiting
    }
    static let identifier = String(describing: MemberCardViewController.self)

    var type: `Type` = .member
    var members = [Member(id: "", role: "'", skills: "")]
    var recruiting = [OpenPosition(role: "", skills: "", number: "1")]
    var firstTimeLoad = true

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
        button.addTarget(self, action: #selector(backToPreviousPage), for: .touchUpInside)
        return button
    }()

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: AddNewCell.identifier, bundle: nil),
                forCellReuseIdentifier: AddNewCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    func layoutView() {
        submitButton.setTitle(
            FindPartnersFormSections.memberBranchButtonTitle,
            for: .normal
        )

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

    @objc func backToPreviousPage() {
        print("back")
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
            return cell

        } else if type == .recruiting && indexPath.row <= recruiting.count - 1 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RecruitingCell.identifier,
                for: indexPath) as? RecruitingCell else {
                fatalError("Cannot create Recruiting Cell")
            }
            cell.layoutCell(info: recruiting[indexPath.row])
            cell.delegate = self
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
                        Member(id: "", role: "", skills: "")
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
