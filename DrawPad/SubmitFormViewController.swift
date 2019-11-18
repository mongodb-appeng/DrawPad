//
//  ubmitFormViewControll.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit
import RealmSwift

class SubmitFormViewController: UIViewController {
  
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var address1: UITextField!
    @IBOutlet weak var address2: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var postalCode: UITextField!
    @IBOutlet weak var country: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("SubmitFormViewController.viewDidLoad")
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        let userContact: UserContact = UserContact(firstName: firstName.text!, lastName: lastName.text!, email: User.email, street1: address1.text!, street2: address2.text!, city: city.text!, state: state.text!, postalCode: postalCode.text!, country: country.text!)
        try! RealmConnection.realm!.write {
            User.imageToSend!.userContact = userContact
        }
        clearAndGo()
    }
    
    @IBAction func skipPressed(_ sender: Any) {
        try! RealmConnection.realm!.write {
            User.imageToSend!.userContact?.firstName = "Skippy"
        }
      clearAndGo()
    }
    
    func clearAndGo() {
        try! RealmConnection.realm!.write {
            // Delete all of the Realm drawing objects
            RealmConnection.realm!.delete(RealmConnection.realm!.objects(LinkedPoint.self))
            RealmConnection.realm!.delete(RealmConnection.realm!.objects(Shape.self))
        }
        
        // Move to the Thank You view
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ThanksViewController") as? ThanksViewController
        self.navigationController!.pushViewController(vc!, animated: true)
    }
    
    
}


