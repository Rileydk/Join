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
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
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
        120
//        if indexPath.section == 0 {
//            if indexPath.row == 0 {
//
//            }
//        }
    }
}

// MARK: - Table View Data Source
extension FindPartnersBasicViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        formState.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SingleLineInputCell.identifier,
            for: indexPath) as? SingleLineInputCell else {
            fatalError("Cannot create single line input cell")
        }
        cell.layoutCell(info: FindPartnersFormSections.sections[0].items[0])
        return cell
    }
}
