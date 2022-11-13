//
//  MockLoginViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/6.
//

import UIKit

let riley = User(
    id: "1qFVcUf1MZh90PDelqfU", name: "Riley Lai",
    email: "ddd@gmail.com",
    thumbnailURL: "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/DA32761A-2775-414C-95E8-F01DCB2CDD66?alt=media&token=c6ac5b7e-1e53-4d0b-813a-eb12c051bf6d"
)
let friend1 = User(
    id: "6z63wggZ1FdOnBEA7Q6s", name: "Friend 1",
    email: "ccc@gmail.com",
    thumbnailURL: "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/25E3357B-A23A-4852-884A-B424FB6ED3FC?alt=media&token=75cc10c7-534b-4e7f-a9fd-45ddcd73d76e"
)
let friend2 = User(
    id: "Pb4yAKffHnXcyIUq9Ypn", name: "Friend 2",
    email: "qqq@gmail.com",
    thumbnailURL: "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/3CD870EC-3520-486A-9651-472378BE2A10?alt=media&token=6afe2b5d-5864-4376-9350-6c02085d8b3c"
)
let newMember = User(
    id: "qvHLIRigbf5UnExgyr8t", name: "New Member",
    email: "eee@gmail.com",
    thumbnailURL: "https://firebasestorage.googleapis.com:443/v0/b/join-82f54.appspot.com/o/F5986CC3-D3EF-4408-AC79-D9D7FC1F8450?alt=media&token=44e11625-5d08-46c7-a8ac-90737e656591"
)

class MockLoginViewController: UIViewController {
    @IBAction func chooseRiley(_ sender: UIButton) {
        myAccount = riley
        goToMainPage()
    }

    @IBAction func chooseFriend1(_ sender: UIButton) {
        myAccount = friend1
        goToMainPage()
    }

    @IBAction func chooseFriend2(_ sender: Any) {
        myAccount = friend2
        goToMainPage()
    }

    @IBAction func chooseNewMember(_ sender: Any) {
        myAccount = newMember
        goToMainPage()
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
