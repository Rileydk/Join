//
//  MyMasterpieceTableViewCell.swift
//  Join
//
//  Created by Riley Lai on 2022/12/2.
//

import UIKit

class MyMasterpieceTableViewCell: TableViewCell {
    @IBOutlet weak var myMasterpieceImageView: UIImageView!
    @IBOutlet weak var myMasterpieceImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var linkButton: UIButton!
    var url: URL?

    var openLinkHandler: ((URL) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        linkButton.tintColor = .White?.withAlphaComponent(0.9)
        linkButton.backgroundColor = .Blue2?.withAlphaComponent(0.7)
        linkButton.contentEdgeInsets = .init(top: 4, left: 4, bottom: 4, right: 4)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        linkButton.layer.cornerRadius = linkButton.frame.width / 2
    }

    func layoutCell(workRecordWithImage: WorkRecordWithImage, cellPadding: CGFloat = 0) {
        guard let image = workRecordWithImage.image else { return }
        myMasterpieceImageViewBottomConstraint.constant = cellPadding
        myMasterpieceImageView.image = image
        if workRecordWithImage.type == .hyperlink,
           let recordURL = URL(string: workRecordWithImage.url) {
            url = recordURL
            linkButton.isHidden = false
        } else {
            linkButton.isHidden = true
        }
    }

    @IBAction func goToLinkPage(_ sender: Any) {
        guard let url = url else { return }
        openLinkHandler?(url)
    }
}
