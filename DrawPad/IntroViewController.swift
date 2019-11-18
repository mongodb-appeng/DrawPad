//
//  IntroViewController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import SwiftUI

// global vars
//var agreedToTerms = false  // TODO replace with an IBOutlet

// This is the introducion view
class IntroViewController: UIViewController {
  
    var agreedToTerms = false
    
//    @IBOutlet weak var agreedToTerms: UIButton!
    
    @IBOutlet weak var agreedToTermsButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
//    @IBOutlet weak var checkTermsButton: UIButton!
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        agreedToTerms = false
//    }
    
    @IBAction func showTermsAndConditionsButton() {
        let alert = UIAlertController(title: "Terms & Conditions", message: "TODO", preferredStyle: UIAlertController.Style.alert)
        // add an action (button)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func isValidEmail(emailStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: emailStr)
    }
    
    @IBAction func agreeToTermsButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        agreedToTerms = sender.isSelected
    }
    
    @IBAction func startDrawingPressed(_ sender: Any) {
        if !isValidEmail(emailStr: emailField.text ?? "") {
            // create the alert
            let alert = UIAlertController(title: "Ooops!", message: "Please enter a valid email", preferredStyle: UIAlertController.Style.alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
            return
        } else if !agreedToTerms {
            // create the alert
            let alert = UIAlertController(title: "Ooops!", message: "You must agree to the Terms & Conditions", preferredStyle: UIAlertController.Style.alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
            return
        }
        User.email = emailField.text!
        emailField.text = ""
        agreedToTerms = false
        agreedToTermsButton.isSelected = false
        
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ViewController") as? ViewController
        self.navigationController!.pushViewController(vc!, animated: true)

    }
    // TODO Remove?
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "startDrawingSegue" { // you define it in the storyboard (click on the segue, then Attributes' inspector > Identifier
            
            if !isValidEmail(emailStr: emailField.text ?? "") {
                // create the alert
                let alert = UIAlertController(title: "Ooops!", message: "Please enter a valid email", preferredStyle: UIAlertController.Style.alert)
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
                return false
            } else if !agreedToTerms {
                // create the alert
                let alert = UIAlertController(title: "Ooops!", message: "You must agree to the Terms & Conditions", preferredStyle: UIAlertController.Style.alert)
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
                return false
            }
            else {
                return true
            }
        }
        return true
    }
}
