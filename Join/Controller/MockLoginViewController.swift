//
//  MockLoginViewController.swift
//  Join
//
//  Created by Riley Lai on 2022/11/6.
//

import UIKit

class MockLoginViewController: UIViewController {
    @IBAction func chooseRiley(_ sender: UIButton) {
        myAccount = riley
        goToMainPage()
    }
    @IBAction func chooseYiChen(_ sender: UIButton) {
        myAccount = yichen
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
