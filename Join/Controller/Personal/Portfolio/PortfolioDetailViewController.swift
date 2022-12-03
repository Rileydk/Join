//
//  PortfolioDetailViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/12/2.
//

import UIKit
import SafariServices

struct WorkRecordWithImage: Hashable {
    var recordID: RecordID
    var type: RecordType
    var image: UIImage?
    var url: URLString
}

class PortfolioDetailViewController: BaseViewController {
    enum Section: CaseIterable {
        case myMasterpiece
    }

    enum Item: Hashable {
        case myMasterpiece(WorkRecordWithImage)
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(UINib(nibName: CreatorHeaderFooterView.identifier, bundle: nil), forCellReuseIdentifier: CreatorHeaderFooterView.identifier)
            tableView.delegate = self
            configureDatasource()
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 200
            tableView.separatorStyle = .none
            tableView.backgroundColor = .Gray5
            tableView.sectionHeaderTopPadding = 0
            // tableView.contentInsetAdjustmentBehavior = .never
        }
    }
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var moreActionButton: UIButton!

    typealias MyMasterpieceDatasource = UITableViewDiffableDataSource<Section, Item>
    var datasource: MyMasterpieceDatasource!
    var workItem: WorkItem?
    var workRecordsWithImages = [WorkRecordWithImage]()
    var user: JUser?
    let cellPadding: CGFloat = 6

    init?(coder: NSCoder, user: JUser, workItem: WorkItem) {
        self.user = user
        self.workItem = workItem
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        getWorkRecordsImages()
        closeButton.backgroundColor = .White?.withAlphaComponent(0.9)
        closeButton.layer.shadowOpacity = 0.2
        closeButton.layer.shadowRadius = 8
        closeButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        closeButton.layer.shadowColor = UIColor.Gray1?.cgColor

        moreActionButton.backgroundColor = .White?.withAlphaComponent(0.9)
        moreActionButton.layer.shadowOpacity = 0.2
        moreActionButton.layer.shadowRadius = 8
        moreActionButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        moreActionButton.layer.shadowColor = UIColor.Gray1?.cgColor
        moreActionButton.contentEdgeInsets = .init(top: 4, left: 10, bottom: 4, right: 10)

        if let user = user, let myID = UserDefaults.standard.string(forKey: UserDefaults.UserKey.uidKey), user.id != myID {
            moreActionButton.showsMenuAsPrimaryAction = true
            let reportAction = UIAction(title: Constant.Portfolio.report, attributes: [], state: .off) { [weak self] _ in
                self?.reportUser()
            }
            var elements: [UIAction] = [reportAction]
            let menu = UIMenu(children: elements)
            moreActionButton.menu = menu
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        closeButton.layer.cornerRadius = closeButton.frame.width / 2
        moreActionButton.layer.cornerRadius = closeButton.frame.height / 2
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    func getWorkRecordsImages() {
        guard let records = workItem?.records else { return }

        let indicator = UIActivityIndicatorView()
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let group = DispatchGroup()
        indicator.startAnimating()
        DispatchQueue.global().async { [weak self] in
            self?.workRecordsWithImages = records.compactMap {
                group.enter()
                var recordImage: UIImage?
                switch $0.type {
                case .image:
                    FirebaseManager.shared.downloadImage(urlString: $0.url) { result in
                        switch result {
                        case .success(let image):
                            recordImage = image
                        case .failure(let err):
                            break
                        }
                        group.leave()
                    }
                case .hyperlink:
                    guard let url = URL(string: $0.url) else { return nil }
                    DispatchQueue.main.async {
                        url.getMetadata { metadata in
                            guard let metadata = metadata else {
                                group.leave()
                                return
                            }
                            metadata.getMetadataImage { image in
                                guard let image = image else { return }
                                recordImage = image
                                group.leave()
                            }
                        }
                    }
                }
                group.wait()
                return WorkRecordWithImage(recordID: $0.recordID, type: $0.type, image: recordImage, url: $0.url)
            }
            group.notify(queue: .main) { [weak self] in
                self?.updateDatasource()
                indicator.stopAnimating()
            }
        }
    }
    @objc func close(_ sender: UIButton) {
       dismiss(animated: true)
    }

    func reportUser() {
        let alert = UIAlertController(title: Constant.FindIdeas.reportAlert, message: nil, preferredStyle: .actionSheet)
        let yesAction = UIAlertAction(title: Constant.Common.confirm, style: .destructive) { [weak self] _ in
            guard let self = self, let user = self.user, let workItem = self.workItem else { return }
            JProgressHUD.shared.showLoading(text: Constant.Common.processing, view: self.view)
            let report = Report(reportID: "", type: .portfolio, reportedObjectID: workItem.workID as! String, reportTime: Date(), reason: nil)
            FirebaseManager.shared.addNewReport(report: report) { result in
                switch result {
                case .success:
                    JProgressHUD.shared.showSuccess(text: Constant.FindIdeas.reportResult, view: self.view)
                case .failure(let err):
                    print(err)
                    JProgressHUD.shared.showFailure(text: Constant.Common.errorShouldRetry, view: self.view)
                }
            }
        }
        let cancelAction = UIAlertAction(title: Constant.Common.cancel, style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(yesAction)
        self.present(alert, animated: true)
    }
}

// MARK: - Table View Delegate
extension PortfolioDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = workRecordsWithImages[indexPath.row].image else { return 0 }
        let imageHeight = image.size.height * (UIScreen.main.bounds.width / image.size.width)
        if indexPath.row == workRecordsWithImages.count - 1 {
            return imageHeight
        } else {
            return imageHeight + cellPadding
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 24
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
}

// MARK: - Datasource
extension PortfolioDetailViewController {
    func configureDatasource() {
        datasource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            return self?.createCell(tableView: tableView, indexPath: indexPath, item: item)
        }
        updateDatasource()
    }

    func createCell(tableView: UITableView, indexPath: IndexPath, item: Item) -> UITableViewCell {
        switch item {
        case .myMasterpiece(let workRecordWithImage):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MyMasterpieceTableViewCell.identifier, for: indexPath) as? MyMasterpieceTableViewCell else {
                fatalError("Cannot create my masterpiece table view cell")
            }
            if indexPath.row == workRecordsWithImages.count - 1 {
                cell.layoutCell(workRecordWithImage: workRecordWithImage)
            } else {
                cell.layoutCell(workRecordWithImage: workRecordWithImage, cellPadding: cellPadding)
            }
            if workRecordWithImage.type == .hyperlink {
                cell.openLinkHandler = { [weak self] url in
                    let safari = SFSafariViewController(url: url)
                    self?.present(safari, animated: true)
                }
            }
            return cell
        }

    }

    func updateDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(workRecordsWithImages.map { .myMasterpiece($0) }, toSection: .myMasterpiece)
        datasource.apply(snapshot, animatingDifferences: true)
    }
}
