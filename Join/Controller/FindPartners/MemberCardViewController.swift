//
//  MemberCardViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/31.
//

import UIKit

class MemberCardViewController: UIViewController {
    enum `Type` {
        case member
        case recruiting
    }
    static let identifier = String(describing: MemberCardViewController.self)

    var type: `Type` = .member
    var members = [Member]()
    var recruiting = [OpenPosition]()
    var firstTimeLoad = true
    var cardAmount = 1

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
        if indexPath.row <= cardAmount - 1 {
            if type == .member {
                return 200
            } else if type == .recruiting {
                return 200
            } else {
                fatalError("No this type")
            }
        } else {
            return 45
        }
    }
}

// MARK: - Table View Data Source
extension MemberCardViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cardAmount + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if type == .member && indexPath.row <= cardAmount - 1 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: MemberCell.identifier,
                for: indexPath) as? MemberCell else {
                fatalError("Cannot create MemberCell")
            }
            return cell

        } else if type == .recruiting && indexPath.row <= cardAmount - 1 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RecruitingCell.identifier,
                for: indexPath) as? RecruitingCell else {
                fatalError("Cannot create Recruiting Cell")
            }
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddNewCell.identifier,
                for: indexPath) as? AddNewCell else {
                fatalError("Cannot create Add New Cell")
            }
            return cell
        }
    }
}
