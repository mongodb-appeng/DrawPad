//
//  RealmConfigViewController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit
import RealmSwift

class RealmConfigViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var pinTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        pinTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        pinTextField.delegate = self
    }
    
    // Use this if you have a UITextField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // get the current text, or use an empty string if that failed
        let currentText = textField.text ?? ""
        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }
        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        // make sure the result is under 5 characters
        return updatedText.count <= 5
    }
    
    @IBAction func closeRealmConfigButton() {
        dismiss(animated: true) {          }
    }
    
    @IBAction func submitRealmCredsButton(_ sender: Any) {
      if (pinTextField.text == Constants.REALM_CONFIG_PIN ){
        let user = SyncUser.current!
        user.logOut()
        if presentingViewController != nil {
          let navigationController = self.presentingViewController as? UINavigationController
          self.dismiss(animated: false, completion: {
            let _ = navigationController?.popToRootViewController(animated: true)
          })
        }
        else {
          self.navigationController!.popToRootViewController(animated: true)
        }
      } else {
            pinTextField.text = nil
            // create the alert
            let alert = UIAlertController(title: "Ooops!", message: "Bad PIN, try again!", preferredStyle: UIAlertController.Style.alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}

