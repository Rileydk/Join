//
//  WorkRecordCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit
import LinkPresentation

class WorkRecordCell: TableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var recordImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!

    var alertHandler: ((UIAlertController) -> Void)?
    var deleteHandler: ((EditableWorkRecord) -> Void)?

    var workRecord: EditableWorkRecord?

    override func awakeFromNib() {
        super.awakeFromNib()
        deleteButton.tintColor = .Red
        containerView.layer.cornerRadius = 10
        deleteButton.tintColor = .Red?.withAlphaComponent(0.7)
    }

    func layoutCell(record: EditableWorkRecord, errorHandler: @escaping () -> Void) {
        workRecord = record
        switch record.type {
        case .image:
            recordImageView.image = record.image
            recordImageView.isHidden = false
            recordImageView.layer.masksToBounds = true
            recordImageView.layer.cornerRadius = 10

        case .hyperlink:
            recordImageView.isHidden = true
            let indicator = UIActivityIndicatorView()
            containerView.addSubview(indicator)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])

            indicator.startAnimating()

            guard let urlStirng = record.url,
                  let url = URL(string: urlStirng) else {

                indicator.stopAnimating()
                let alert = UIAlertController(title: Constant.Common.notValidURL, message: nil, preferredStyle: .alert)
                let action = UIAlertAction(title: Constant.Common.ok, style: .default)
                alert.addAction(action)
                self.alertHandler?(alert)
                errorHandler()

                return
            }

            url.getMetadata { [weak self] metadata in
                guard let self = self else { return }
                if let metadata = metadata, let url = metadata.originalURL {
                    let linkView = LPLinkView(url: url)
                    linkView.metadata = metadata
                    indicator.stopAnimating()

                    linkView.translatesAutoresizingMaskIntoConstraints = false
                    self.containerView.addSubview(linkView)
                    NSLayoutConstraint.activate([
                        linkView.topAnchor.constraint(equalTo: self.containerView.topAnchor),
                        linkView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
                        linkView.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
                        linkView.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
                    ])
                } else {
                    indicator.stopAnimating()
                    let alert = UIAlertController(title: Constant.Common.notValidURL, message: nil, preferredStyle: .alert)
                    let action = UIAlertAction(title: Constant.Common.ok, style: .default)
                    alert.addAction(action)
                    self.alertHandler?(alert)
                    errorHandler()
                }
            }
        }
    }

    @IBAction func deleteRecord(_ sender: UIButton) {
        deleteHandler?(workRecord!)
    }
}
