//
//  WorkHeaderView.swift
//  Join
//
//  Created by Riley Lai on 2022/11/18.
//

import UIKit
import PhotosUI

protocol WorkHeaderViewDelegate: AnyObject {
    func workHeaderView(_ cell: WorkHeaderView, didSetImage image: UIImage)
}

class WorkHeaderView: TableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!

    var alertPresentHandler: ((UIAlertController) -> Void)?
    var cameraPresentHandler: ((UIImagePickerController) -> Void)?
    var libraryPresentHandler: ((PHPickerViewController) -> Void)?
    weak var delegate: WorkHeaderViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .White
        titleLabel.text = "上傳檔案"
        titleLabel.textColor = .Gray1
        addButton.tintColor = .Blue1
    }

    func layoutHeader(addButtonShouldEnabled: Bool) {
        if addButtonShouldEnabled {
            addButton.isEnabled = true
            addButton.tintColor = .Blue1
        } else {
            addButton.isEnabled = false
            addButton.tintColor = .Gray3
        }
    }

    @IBAction func addNewFile(_ sender: UIButton) {
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
extension WorkHeaderView: PHPickerViewControllerDelegate {
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
                    self.delegate?.workHeaderView(self, didSetImage: image)
                }
            }
        }
    }
}

extension WorkHeaderView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // swiftlint:disable line_length
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) { [unowned self] in
                self.delegate?.workHeaderView(self, didSetImage: image)
            }
        } else {
            picker.dismiss(animated: true)
        }
    }
}
