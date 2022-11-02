//
//  UIImage.swift
//  Join
//
//  Created by Riley Lai on 2022/11/2.
//

import UIKit

extension UIImage {
    enum ImageQuality: CGFloat {
        case lowest = 0
        case low = 0.25
        case medium = 0.5
        case hight = 0.75
        case highest = 1
    }

    func jpeg(_ quality: ImageQuality) -> Data? {
        jpegData(compressionQuality: quality.rawValue)
    }

    static func fileSize(image: Data) {
        let imgData = NSData(data: image)
        let imageSize: Int = imgData.count
        print("actual size of image in KB: %f ", Double(imageSize) / 1000.0)
    }
}
