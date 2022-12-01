//
//  AddPortfolioViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit
import VisionKit

class AddPortfolioViewController: BaseViewController {
    enum Section: String, CaseIterable {
        case name = "作品名稱"
//        case description
        case file
    }

    enum Item: Hashable {
        case name(Work)
//        case description(String)
        case file(UIImage)
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(
                UINib(nibName: SingleLineInputCell.identifier, bundle: nil),
                forCellReuseIdentifier: SingleLineInputCell.identifier)
            tableView.register(
                UINib(nibName: MultilineInputCell.identifier, bundle: nil),
                forCellReuseIdentifier: MultilineInputCell.identifier
            )
            tableView.register(
                UINib(nibName: WorkRecordCell.identifier, bundle: nil),
                forCellReuseIdentifier: WorkRecordCell.identifier)
            tableView.register(
                UINib(nibName: WorkHeaderView.identifier, bundle: nil),
                forHeaderFooterViewReuseIdentifier: WorkHeaderView.identifier)
            tableView.delegate = self
            configureDatasource()
            tableView.separatorStyle = .none
            tableView.backgroundColor = .White
        }
    }

    typealias WorkDatasource = UITableViewDiffableDataSource<Section, Item>
    private var datasource: WorkDatasource!
    let firebaseManager = FirebaseManager.shared
    var work = Work(
        workID: "", name: "", latestUpdatedTime: Date(),
        creator: UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)!)

    var scannedContent: VNDocumentCameraScan? {
        didSet {
            guard let scannedContent = scannedContent else { return }
            for index in 0 ..< scannedContent.pageCount {
                recordsImages.append(scannedContent.imageOfPage(at: index))
            }
        }
    }
    var recordsImages = [UIImage]() {
        didSet {
            // FIXME: - 暫時不能上傳多張照片，需要在上傳過且刪除已選照片前停止加入新照片，且 table view diffable 沒有包含 header，因此同時使用 reload data
            tableView.reloadData()
            updateDatasource()
        }
    }
    var records = [WorkRecord]()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self, action: #selector(addNewWork))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Discard", style: .plain, target: self, action: #selector(backToPreviousPage))
    }

    @objc func addNewWork() {
        guard isProperlyFilled() else {
            alertNeedFilled()
            return
        }

        JProgressHUD.shared.showSaving(view: self.view)

        var myWorkID: WorkID?
        var myRecordsIDsOrder = [RecordID]()
        var shouldContinue = true

        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            let group = DispatchGroup()
            group.enter()
            for image in self.recordsImages {
                self.firebaseManager.uploadImage(image: image.jpeg(.lowest)!) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let urlString):
                        self.records.append(WorkRecord(recordID: "", url: urlString))
                    case .failure(let err):
                        shouldContinue = false
                        JProgressHUD.shared.showFailure(view: self.view)
                        print(err)
                    }
                    group.leave()
                }
            }

            group.wait()
            guard !self.records.isEmpty && shouldContinue else { return }
            group.enter()
            self.firebaseManager.addNewWork(work: self.work) { result in
                switch result {
                case .success(let workID):
                    myWorkID = workID
                case .failure(let err):
                    print(err)
                    shouldContinue = false
                    JProgressHUD.shared.showFailure(view: self.view)
                }
                group.leave()
            }

            group.wait()
            guard let myWorkID = myWorkID, shouldContinue else { return }
            group.enter()
            self.firebaseManager.addNewRecords(records: self.records, to: myWorkID) { result in
                switch result {
                case .success(let recordsIDsOrder):
                    myRecordsIDsOrder = recordsIDsOrder
                case .failure(let err):
                    shouldContinue = false
                    JProgressHUD.shared.showFailure(view: self.view)
                    print(err)
                }
                group.leave()
            }

            group.wait()
            guard !myRecordsIDsOrder.isEmpty && shouldContinue else { return }
            group.enter()
            self.firebaseManager.updateWorkRecordsOrder(of: myWorkID, by: myRecordsIDsOrder) { result in
                group.leave()
                switch result {
                case .success:
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showSuccess(view: self.view) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                case .failure(let err):
                    group.notify(queue: .main) {
                        JProgressHUD.shared.showFailure(text: err.localizedDescription, view: self.view)
                    }

                }
            }
        }
    }

    func isProperlyFilled() -> Bool {
        !work.name.isEmpty && !recordsImages.isEmpty
    }

    func alertNeedFilled() {
        let alert = UIAlertController(title: "名稱和檔案都是必填項目喔！", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }

    @objc func backToPreviousPage() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Table View Delegate
extension AddPortfolioViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section.allCases[indexPath.section]
        switch section {
        case .name: return 100
        case .file: return 250
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section.allCases[section]
        switch section {
        case .name: return 0
        case .file: return 70
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = Section.allCases[section]
        if section == .file {
            guard let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: WorkHeaderView.identifier
                ) as? WorkHeaderView else {
                fatalError("Cannot load Work Header View")
            }
            header.layoutHeader(addButtonShouldEnabled: recordsImages.isEmpty)
            header.delegate = self
            header.alertPresentHandler = { [weak self] alert in
                self?.present(alert, animated: true)
            }
            header.cameraPresentHandler = { [weak self] controller in
                self?.present(controller, animated: true)
            }
            header.libraryPresentHandler = { [weak self] picker in
                self?.present(picker, animated: true)
            }
            header.scannerPresentHandler = { [weak self] scanner in
                self?.present(scanner, animated: true)
            }
            return header
        } else {
            return nil
        }
    }
}

// MARK: - Datasource
extension AddPortfolioViewController {
    func configureDatasource() {
        // swiftlint:disable line_length
        datasource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            self?.createCell(tableView: tableView, indexPath: indexPath, item: item)
        }
        updateDatasource()
    }

    func createCell(tableView: UITableView, indexPath: IndexPath, item: Item) -> UITableViewCell {
        switch item {
        case .name(let work):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SingleLineInputCell.identifier, for: indexPath) as? SingleLineInputCell else {
                fatalError("Cannot load single line input cell")
            }
            cell.layoutCell(withTitle: .workName, value: work.name)
            cell.updateWorkName = { [weak self] workName in
                guard let self = self else { return }
                self.work.name = workName
            }
            return cell
        case .file(let image):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: WorkRecordCell.identifier, for: indexPath) as? WorkRecordCell else {
                fatalError("Cannot load work record cell")
            }
            cell.layoutCell(recordImage: image)
            return cell
        }
    }

    func updateDatasource() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(applyDatasource), with: nil, afterDelay: 0.3)
    }

    @objc func applyDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.name(work)], toSection: .name)
        snapshot.appendItems(recordsImages.map { .file($0) }, toSection: .file)
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Work Header View Delegate
extension AddPortfolioViewController: WorkHeaderViewDelegate {
    func workHeaderView(_ cell: WorkHeaderView, didSetImage image: UIImage) {
        recordsImages.append(image)
    }
}

// MARK: - VNDocumentViewController Delegate
extension AddPortfolioViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        scannedContent = scan
        dismiss(animated: true)
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
        dismiss(animated: true)
    }
}
