//
//  PersonalMainThumbnailCell.swift
//  Join
//
//  Created by Riley Lai on 2022/11/3.
//

import UIKit
import PhotosUI

class PersonalMainThumbnailCell: TableViewCell {
    let firebaseManager = FirebaseManager.shared

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    var updateImage: ((UIImage) -> Void)?
    var alertPresentHandler: ((UIAlertController) -> Void)?
    var cameraPresentHandler: ((UIImagePickerController) -> Void)?
    var libraryPresentHandler: ((PHPickerViewController) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2
    }

    func layoutCell(isEditing: Bool) {
        nameLabel.text = UserDefaults.standard.string(forKey: UserDefaults.UserKey.userNameKey)
        let imageURL = URL(string: UserDefaults.standard.string(forKey: UserDefaults.UserKey.userThumbnailURLKey)!)
                        ?? URL(string: FindPartnersFormSections.placeholderImageURL)!
        thumbnailImageView.kf.setImage(with: imageURL)

        if isEditing {
            thumbnailImageView.isUserInteractionEnabled = true
            let tapRecognizer = UITapGestureRecognizer(
                target: self, action: #selector(showSourceTypeActionSheet))
            thumbnailImageView.addGestureRecognizer(tapRecognizer)
        } else {
            thumbnailImageView.isUserInteractionEnabled = false
        }
    }

    @objc func showSourceTypeActionSheet() {
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
}

// MARK: - PHPicker Controller Delegate
extension PersonalMainThumbnailCell: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        picker.dismiss(animated: true)

        if let itemProvider = results.first?.itemProvider,
           itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in

                if let error = error {
                    print(error)
                }

                DispatchQueue.main.async {
                    guard let image = image as? UIImage else { return }
                    self?.thumbnailImageView.image = image
                    self?.updateImage?(image)
                }
            }
        }
    }
}

// MARK: - Image Picker Controller Delegate, Navigation Controller Delegate
extension PersonalMainThumbnailCell: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // swiftlint:disable line_length
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) { [weak self] in
                self?.thumbnailImageView.image = image
                self?.updateImage?(image)
            }
        } else {
            picker.dismiss(animated: true)
        }
    }
}
