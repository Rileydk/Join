//
//  UIImage.swift
//  Join
//
//  Created by Riley Lai on 2022/11/2.
//

import UIKit

enum JImages: String {
    // swiftlint:disable identifier_name
    case cover_image_placeholder_vertical
    case Icons_24px_Back
    case Icons_24px_Calendar
    case Icons_24px_Close
    case Icons_24px_GoNext
    case Icons_24px_Hourglass
    case Icons_24px_Location
    case Icons_24px_More
    case Icons_24px_Tools
    case Icons_24px_Person
    case Icons_24px_VerticalMore
}

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
