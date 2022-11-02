//
//  ImagePickerCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/1.
//

import UIKit
import PhotosUI

protocol ImagePickerCellDelegate: AnyObject {
    func imagePickerCell(_ cell: ImagePickerCell, didSetImage image: Data?)
}

class ImagePickerCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var imagePickerView: UIImageView!
    var presentHandler: ((PHPickerViewController) -> Void)?
    weak var delegate: ImagePickerCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        imagePickerView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectPhoto))
        imagePickerView.addGestureRecognizer(tapGestureRecognizer)
    }

    func layoutCell(info: ItemInfo) {
        titleLabel.text = info.name
        mustFillSignLabel.isHidden = !info.must
    }

    @objc func selectPhoto() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presentHandler?(picker)
    }
}

// MARK: - PHPicker Controller Delegate
extension ImagePickerCell: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        picker.dismiss(animated: true)

        if let itemProvider = results.first?.itemProvider,
            itemProvider.canLoadObject(ofClass: UIImage.self) {
                let previousImage = imagePickerView.image
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in

                    if let error = error {
                        print(error)
                    }

                    DispatchQueue.main.async {
                        guard let strongSelf = self,
                            let image = image as? UIImage,
                            strongSelf.imagePickerView.image == previousImage else { return }

                        let imageData = image.jpeg(.lowest)
                        strongSelf.imagePickerView.image = UIImage(data: imageData!)
                        strongSelf.delegate?.imagePickerCell(strongSelf, didSetImage: imageData)

                        let imgData = NSData(data: imageData!)
                        var imageSize: Int = imgData.count
                        print("actual size of image in KB: %f ", Double(imageSize) / 1000.0)
                    }
                }
        }
    }
}
