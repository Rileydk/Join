//
//  AddPortfolioViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit
import VisionKit
import LinkPresentation

struct EditableWorkRecord: Hashable {
    var recordID: RecordID
    var type: RecordType
    var image: UIImage?
    var url: URLString?

    init(recordID: RecordID, type: RecordType, image: UIImage?, url: URLString?) {
        self.recordID = recordID
        self.type = type
        self.image = image
        self.url = url
    }

    init(recordID: RecordID, type: RecordType, url: URLString?) {
        self.recordID = recordID
        self.type = type
        self.image = nil
        self.url = url
    }
}

class AddPortfolioViewController: BaseViewController {
    enum Section: String, CaseIterable {
        case name = "作品名稱"
//        case description
        case file
    }

    enum Item: Hashable {
        case name(Work)
//        case description(String)
        case file(EditableWorkRecord)
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
            tableView.backgroundColor = backgroundColor
        }
    }
    var rightBarButton: PillButton?
    let backgroundColor = Constant.ColorTheme.lightBackgroundColor
    private var provider = LPMetadataProvider()

    typealias WorkDatasource = UITableViewDiffableDataSource<Section, Item>
    private var datasource: WorkDatasource!
    let firebaseManager = FirebaseManager.shared
    var work = Work(
        workID: "", name: "", latestUpdatedTime: Date(),
        creator: UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey)!) {
            didSet {
                checkCanSave()
            }
        }

    var editableRecords = [EditableWorkRecord]() {
        didSet {
            checkCanSave()
        }
    }
    var finalRecords = [WorkRecord]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constant.Portfolio.addPortfolio
        let rightButtonConfig = UIButton.Configuration.filled()
        rightBarButton = PillButton(configuration: rightButtonConfig)
        rightBarButton!.setTitle(Constant.Common.save, for: .normal)
        rightBarButton!.addTarget(self, action: #selector(addNewWork), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton!)
        checkCanSave()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: JImages.Icon_24px_Close.rawValue), style: .plain,
            target: self, action: #selector(backToPreviousPage))
    }

    @objc func addNewWork() {
        JProgressHUD.shared.showSaving(view: self.view)

        var myWorkID: WorkID?
        var myRecordsIDsOrder = [RecordID]()
        var shouldContinue = true

        firebaseManager.firebaseQueue.async { [weak self] in
            guard let self = self else { return }
            let group = DispatchGroup()
            for record in self.editableRecords {
                group.enter()
                if record.type == .image, let image = record.image {
                    self.firebaseManager.uploadImage(image: image.jpeg(.lowest)!) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let urlString):
                            self.finalRecords.append(WorkRecord(recordID: "", type: .image, url: urlString))
                        case .failure(let err):
                            shouldContinue = false
                            JProgressHUD.shared.showFailure(view: self.view)
                            print(err)
                        }
                        group.leave()
                    }
                } else if record.type == .hyperlink, let url = record.url {
                    self.finalRecords.append(WorkRecord(recordID: "", type: .hyperlink, url: url))
                    group.leave()
                } else {
                    break
                }
            }

            group.wait()
            guard !self.finalRecords.isEmpty && shouldContinue else { return }
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
            self.firebaseManager.addNewRecords(records: self.finalRecords, to: myWorkID) { result in
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

    func checkCanSave() {
        if !work.name.isEmpty && !editableRecords.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
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
            header.layoutHeader(addButtonShouldEnabled: editableRecords.isEmpty)
            header.backgroundColor = backgroundColor
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
            header.pastingURLHandler = { [weak self] in
                guard let self = self else { return }
                guard UIPasteboard.general.hasStrings else {
                    JProgressHUD.shared.showFailure(text: Constant.Common.emptyURL, view: self.view)
                    return
                }
                if let copiedText = UIPasteboard.general.string, URL(string: copiedText) != nil {
                    if self.editableRecords.contains(where: { $0.url == copiedText }) {
                        JProgressHUD.shared.showFailure(text: Constant.Common.duplicatedURL, view: self.view)
                    } else {
                        let workRecord = EditableWorkRecord(recordID: "", type: .hyperlink, url: copiedText)
                        self.editableRecords.append(workRecord)
                        var snapshot = self.datasource.snapshot()
                        snapshot.appendItems([.file(workRecord)])
                        self.datasource.apply(snapshot, animatingDifferences: true)
                    }

                } else {
                    JProgressHUD.shared.showFailure(text: Constant.Common.notValidURL, view: self.view)
                }
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
            cell.contentView.backgroundColor = backgroundColor
            cell.updateWorkName = { [weak self] workName in
                guard let self = self else { return }
                self.work.name = workName
            }
            return cell
        case .file(let editableRecord):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: WorkRecordCell.identifier, for: indexPath) as? WorkRecordCell else {
                fatalError("Cannot load work record cell")
            }

            cell.layoutCell(record: editableRecord) { [weak self] in
                guard let self = self else { return }
                self.editableRecords.remove(at: self.editableRecords.firstIndex(of: editableRecord)!)
                var snapshot = self.datasource.snapshot()
                snapshot.deleteItems([.file(editableRecord)])
                self.datasource.apply(snapshot, animatingDifferences: true)
            }
            cell.deleteHandler = { [weak self] workRecord in
                guard let self = self else { return }
                self.editableRecords.remove(at: self.editableRecords.firstIndex(of: workRecord)!)
                var snapshot = self.datasource.snapshot()
                snapshot.deleteItems([.file(workRecord)])
                self.datasource.apply(snapshot, animatingDifferences: true)
            }

            if editableRecord.type == .hyperlink {
                cell.alertHandler = { [weak self] alert in
                    self?.present(alert, animated: true)
                }
            }

            cell.contentView.backgroundColor = backgroundColor
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
        snapshot.appendItems(editableRecords.map { .file($0) }, toSection: .file)
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Work Header View Delegate
extension AddPortfolioViewController: WorkHeaderViewDelegate {
    func workHeaderView(_ cell: WorkHeaderView, didSetImage image: UIImage) {
        let workRecord = EditableWorkRecord(recordID: "", type: .image, image: image, url: "")
        editableRecords.append(workRecord)
        var snapshot = self.datasource.snapshot()
        snapshot.appendItems([.file(workRecord)])
        self.datasource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - VNDocumentViewController Delegate
extension AddPortfolioViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        dismiss(animated: true)

        for index in 0 ..< scan.pageCount {
            let workRecord = EditableWorkRecord(
                recordID: "", type: .image,
                image: scan.imageOfPage(at: index), url: "")
            editableRecords.append(workRecord)
            var snapshot = self.datasource.snapshot()
            snapshot.appendItems([.file(workRecord)])
            self.datasource.apply(snapshot, animatingDifferences: true)
        }
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
        dismiss(animated: true)
    }
}
