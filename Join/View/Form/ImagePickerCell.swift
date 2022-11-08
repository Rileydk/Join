//
//  ImagePickerCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/1.
//

import UIKit
import PhotosUI

protocol ImagePickerCellDelegate: AnyObject {
    func imagePickerCell(_ cell: ImagePickerCell, didSetImage image: UIImage)
}

class ImagePickerCell: TableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mustFillSignLabel: UILabel!
    @IBOutlet weak var imagePickerView: UIImageView!
    var alertPresentHandler: ((UIAlertController) -> Void)?
    var cameraPresentHandler: ((UIImagePickerController) -> Void)?
    var libraryPresentHandler: ((PHPickerViewController) -> Void)?
    weak var delegate: ImagePickerCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        imagePickerView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addPhoto))
        imagePickerView.addGestureRecognizer(tapGestureRecognizer)
    }

    func layoutCell(info: ItemInfo) {
        titleLabel.text = info.name
        mustFillSignLabel.isHidden = !info.must
    }

    @objc func addPhoto() {
        showSourceTypeActionSheet()
    }

    func showSourceTypeActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "開啟相機", style: .default) { _ in
            self.showCamera()
            alert.dismiss(animated: true)
        }
        let photoLibraryAction = UIAlertAction(title: "從相簿選取", style: .default) { _ in
            self.showPhotoLibrary()
            alert.dismiss(animated: true)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            alert.dismiss(animated: true)
        }

        alert.addAction(cameraAction)
        alert.addAction(photoLibraryAction)
        alert.addAction(cancelAction)
        alertPresentHandler?(alert)
    }

    func showPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        libraryPresentHandler?(picker)
    }

    func showCamera() {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert(title: "提醒", message: "此裝置沒有相機")
            return
        }
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = self
        cameraPresentHandler?(controller)
    }

    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { _ in
            alert.dismiss(animated: true)
        }
        alert.addAction(action)
        alertPresentHandler?(alert)
    }
}

// MARK: - PHPicker Controller Delegate
extension ImagePickerCell: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        picker.dismiss(animated: true)

        if let itemProvider = results.first?.itemProvider,
            itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [unowned self] (image, error) in

                    if let error = error {
                        print(error)
                    }

                    DispatchQueue.main.async {
                        guard let image = image as? UIImage else { return }
                        self.imagePickerView.image = image
                        self.delegate?.imagePickerCell(self, didSetImage: image)
                    }
                }
        }
    }
}

extension ImagePickerCell: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // swiftlint:disable line_length
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) { [unowned self] in
                self.imagePickerView.image = image
                self.delegate?.imagePickerCell(self, didSetImage: image)
            }
        } else {
            picker.dismiss(animated: true)
        }
    }
}
