//
//  GroupCreationHeaderCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/10.
//

import UIKit
import PhotosUI

protocol GroupCreationHeaderCellDelegate: AnyObject {
    func groupCreationHeaderCell(_ cell: GroupCreationHeaderCell, didSetImage image: UIImage)
    func groupCreationHeaderCell(_ cell: GroupCreationHeaderCell, didAddName name: String)
}

class GroupCreationHeaderCell: CollectionViewCell {
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameTextField: UITextField!

    var alertPresentHandler: ((UIAlertController) -> Void)?
    var cameraPresentHandler: ((UIImagePickerController) -> Void)?
    var libraryPresentHandler: ((PHPickerViewController) -> Void)?
    weak var delegate: GroupCreationHeaderCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        groupImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addPhoto))
        groupImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func addPhoto() {
        showSourceTypeActionSheet()
    }

    func showSourceTypeActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photoLibraryAction = UIAlertAction(title: "從相簿選取", style: .default) { _ in
            self.showPhotoLibrary()
            alert.dismiss(animated: true)
        }
        let cameraAction = UIAlertAction(title: "開啟相機", style: .default) { _ in
            self.showCamera()
            alert.dismiss(animated: true)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            alert.dismiss(animated: true)
        }

        alert.addAction(photoLibraryAction)
        alert.addAction(cameraAction)
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

    @IBAction func addName(_ sender: UITextField) {
        delegate?.groupCreationHeaderCell(self, didAddName: groupNameTextField.text ?? "")
    }
}

// MARK: - PHPicker Controller Delegate
extension GroupCreationHeaderCell: PHPickerViewControllerDelegate {
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
                    self.groupImageView.image = image
                    self.delegate?.groupCreationHeaderCell(self, didSetImage: image)
                }
            }
        }
    }
}

extension GroupCreationHeaderCell: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // swiftlint:disable line_length
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) { [unowned self] in
                self.groupImageView.image = image
                self.delegate?.groupCreationHeaderCell(self, didSetImage: image)
            }
        } else {
            picker.dismiss(animated: true)
        }
    }
}
