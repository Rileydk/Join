////
////  MockLoginViewController.swift
////  Join
////
////  Created by Riley Lai on 2022/11/6.
////
//
//import UIKit
//
////let rileyID = "u1TWC1cOQafOstYeyYnpCjXSe653"
////let friendID = "6z63wggZ1FdOnBEA7Q6s"
////let newMemberID = "Pb4yAKffHnXcyIUq9Yp"
////let passengerID = "qvHLIRigbf5UnExgyr8t"
//
//class MockLoginViewController: BaseViewController {
//    @IBAction func chooseRiley(_ sender: UIButton) {
//        saveToUserDefaults(userID: rileyID) { [weak self] result in
//            switch result {
//            case .success:
//                self?.goToMainPage()
//            case .failure(let err):
//                print(err)
//            }
//        }
//    }
//
//    @IBAction func chooseFriend(_ sender: UIButton) {
//        saveToUserDefaults(userID: friendID) { [weak self] result in
//            switch result {
//            case .success:
//                self?.goToMainPage()
//            case .failure(let err):
//                print(err)
//            }
//        }
//    }
//
//    @IBAction func chooseNewMember(_ sender: Any) {
//        saveToUserDefaults(userID: newMemberID) { [weak self] result in
//            switch result {
//            case .success:
//                self?.goToMainPage()
//            case .failure(let err):
//                print(err)
//            }
//        }
//    }
//
//    @IBAction func choosePassenger(_ sender: Any) {
//        saveToUserDefaults(userID: passengerID) { [weak self] result in
//            switch result {
//            case .success:
//                self?.goToMainPage()
//            case .failure(let err):
//                print(err)
//            }
//        }
//    }
//
//    func saveToUserDefaults(userID: UserID, completion: @escaping (Result<String, Error>) -> Void) {
//        let firebaseManager = FirebaseManager.shared
//        firebaseManager.lookUpUser(userID: userID) { result in
//            switch result {
//            case .success(let user):
//                UserDefaults.standard.setValue(user.id, forKey: UserDefaults.UserKey.uidKey)
//                UserDefaults.standard.setValue(user.thumbnailURL, forKey: UserDefaults.UserKey.userThumbnailURLKey)
//                UserDefaults.standard.setValue(user.name, forKey: UserDefaults.UserKey.userNameKey)
//                UserDefaults.standard.setValue(user.interests, forKey: UserDefaults.UserKey.userInterestsKey)
//                completion(.success("Success"))
//            case .failure(let err):
//                completion(.failure(err))
//            }
//        }
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "GoToMainPage" {
//            let mainVC = segue.destination
//            mainVC.modalPresentationStyle = .overFullScreen
//        }
//    }
//
//    func goToMainPage() {
//        performSegue(withIdentifier: "GoToMainPage", sender: nil)
//    }
//}
