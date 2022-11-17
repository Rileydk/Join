//
//  MockLoginViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/6.
//

import UIKit

let rileyID = "u1TWC1cOQafOstYeyYnpCjXSe653"
let friendID = "6z63wggZ1FdOnBEA7Q6s"
let newMemberID = "Pb4yAKffHnXcyIUq9Ypn"
let passengerID = "qvHLIRigbf5UnExgyr8t"

class MockLoginViewController: UIViewController {
    @IBAction func chooseRiley(_ sender: UIButton) {
        saveToUserDefaults(userID: rileyID)
        goToMainPage()
    }

    @IBAction func chooseFriend(_ sender: UIButton) {
        saveToUserDefaults(userID: friendID)
        goToMainPage()
    }

    @IBAction func chooseNewMember(_ sender: Any) {
        saveToUserDefaults(userID: newMemberID)
        goToMainPage()
    }

    @IBAction func choosePassenger(_ sender: Any) {
        saveToUserDefaults(userID: passengerID)
        goToMainPage()
    }

    func saveToUserDefaults(userID: UserID) {
        let firebaseManager = FirebaseManager.shared
        firebaseManager.lookUpUser(userID: userID) { result in
            switch result {
            case .success(let user):
                UserDefaults.standard.setValue(user.id, forKey: UserDefaults.UserKey.uidKey)
                UserDefaults.standard.setValue(user.thumbnailURL, forKey: UserDefaults.UserKey.userThumbnailURLKey)
                UserDefaults.standard.setValue(user.name, forKey: UserDefaults.UserKey.userNameKey)
                UserDefaults.standard.setValue(user.interests, forKey: UserDefaults.UserKey.userInterestsKey)

                let mainStoryboard = UIStoryboard(name: StoryboardCategory.main.rawValue, bundle: nil)
                guard let tabBarController = mainStoryboard.instantiateViewController(
                    withIdentifier: TabBarController.identifier
                ) as? TabBarController else {
                    fatalError("Cannot load tab bar controller")
                }
                tabBarController.selectedIndex = 0
                tabBarController.modalPresentationStyle = .fullScreen
                self.present(tabBarController, animated: false)
            case .failure(let err):
                print(err)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToMainPage" {
            let mainVC = segue.destination
            mainVC.modalPresentationStyle = .overFullScreen
        }
    }

    func goToMainPage() {
        performSegue(withIdentifier: "GoToMainPage", sender: nil)
    }
}
