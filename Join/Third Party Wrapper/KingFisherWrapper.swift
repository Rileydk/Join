//
//  KingFisherWrapper.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit
import Kingfisher

extension UIImageView {
    enum ImagePlaceholder: String {
        case projectImage
        case userThumbnail
    }

    func loadImage(_ urlString: String?, placeHolder: UIImage? = nil) {
        guard let urlString = urlString else { return }
        let url = URL(string: urlString)
        self.kf.indicatorType = .activity
        self.kf.setImage(with: url, placeholder: placeHolder)
    }
}
