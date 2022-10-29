//
//  FindPartnersBasicViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/10/29.
//

import UIKit

class FindPartnersBasicViewController: UIViewController {

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
                UINib(nibName: GoNextPageCell.identifier, bundle: nil),
                forCellReuseIdentifier: GoNextPageCell.identifier
            )
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.estimatedRowHeight = UITableView.automaticDimension
        }
    }

    var formState = FindPartnersFormSections.basicSection

    override func viewDidLoad() {
        super.viewDidLoad()
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
                withIdentifier: GoNextPageCell.identifier,
                for: indexPath) as? GoNextPageCell else {
                fatalError("Cannot create single line input cell")
            }
            cell.layoutCell(info: formState.items[indexPath.row], containsTags: true)
            return cell
        }
    }
}
