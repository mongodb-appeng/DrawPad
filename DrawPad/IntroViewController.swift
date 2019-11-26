//
//  IntroViewController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import SwiftUI

// global vars
// This is the introducion view
class IntroViewController: BaseViewController {
  
    var agreedToTerms = false
    var gotValidEmail = false  // APPENG-72
    
    override func viewDidLoad() {
       super.viewDidLoad()
        print("IntroViewController.viewDidLoad")
        self.hideKeyboardWhenTappedAround()
        gotValidEmail = false
        agreedToTerms = false
        checkBoxTCPP.isSelected = false
        configDrawingButton()
    }
    
    @IBOutlet weak var checkBoxTCPP: UIButton!
    @IBOutlet weak var startDrawingButton: UIButton! // APPENG-72
    @IBOutlet weak var agreedToTermsButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
    
    @IBAction func enteringEmailField(_ sender: UITextField) {
        isValidEmail(emailStr: emailField.text ?? "")
    }
    func configDrawingButton() {
        startDrawingButton.backgroundColor = (agreedToTerms && gotValidEmail)
          ? UIColor(red: 19/255, green: 164/255, blue: 63/255, alpha: 1.0) : UIColor.lightGray// APPENG-72
               startDrawingButton.isEnabled = (agreedToTerms && gotValidEmail) ? true : false
    }
    func isValidEmail(emailStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        gotValidEmail = emailPred.evaluate(with: emailStr)
      configDrawingButton()
        return gotValidEmail  // APPENG-72
    }
    @IBAction func agreeToTermsButton(_ sender: UIButton) {
       
        self.view.endEditing(false)
        sender.isSelected = !sender.isSelected
        agreedToTerms = sender.isSelected
        configDrawingButton()
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
        emailField.endEditing(true)
        agreedToTerms = false
        agreedToTermsButton.isSelected = false
        startDrawingButton.backgroundColor = UIColor.lightGray
        startDrawingButton.isEnabled = false
        
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DrawViewController") as? DrawViewController
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


// Put this piece of code anywhere you like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
