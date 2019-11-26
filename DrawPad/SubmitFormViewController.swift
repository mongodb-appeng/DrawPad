//
//  ubmitFormViewControll.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit
import RealmSwift

class SubmitFormViewController: BaseViewController {
  
    @IBOutlet weak var shippingWarningLabel: UILabel!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var address1: UITextField!
    @IBOutlet weak var address2: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var postalCode: UITextField!
    @IBOutlet weak var country: UITextField!
    @IBOutlet weak var photoCaptureOverlay: PhotoCaptureOverlayView!
    public var drawing: UIImage?
    @IBOutlet weak var snapShotImageView: UIImageView!
    @IBOutlet weak var deleteSnapButton: UIButton!
    private var snapShotImage: UIImage? {
        didSet {
            snapShotImageView.image = snapShotImage
            deleteSnapButton.isHidden = snapShotImage == nil
        }
    }
    
    
    func isValidInput(text: String!, minLength: Int!) -> Bool {
        return text.count >= minLength
    }
    
    func isSubmitAllowed() -> Bool {
        return isValidInput(text: firstName.text ?? "", minLength: 2) &&
        isValidInput(text: lastName.text ?? "",  minLength: 2) &&
        isValidInput(text: address1.text ?? "",  minLength: 2) &&
        isValidInput(text: city.text ?? "",  minLength: 2) &&
        isValidInput(text: state.text ?? "",  minLength: 2) &&
        isValidInput(text: postalCode.text ?? "",  minLength: 2) &&
        isValidInput(text: country.text ?? "",  minLength: 2)
    }
    
    @IBAction func snapPressed() {
        photoCaptureOverlay.getCompositeImage { [weak self] image in
            self?.snapShotImage = image
        }
    }
    @IBAction func deleteSnapPressed() {
        snapShotImage = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("SubmitFormViewController.viewDidLoad")
        photoCaptureOverlay.startCameraPreview(with: drawing)
    }
    
    func extractImage() -> Data? {
      guard let image = self.snapShotImage?.pngData() else {
        print("No snapshot image")
        return nil
      }
      return image
    }
    
    func addressIsConfirmed() {
        let image = extractImage()
        var imageURL = ""
        if image != nil {
          imageURL = AWS.uploadImage(image: image!, email: User.email, tag: "snapshot")
        }
        try! RealmConnection.realmAtlas!.write {
          User.imageToSend!.userContact!.setUser(firstName: firstName.text!, lastName: lastName.text!, email: User.email, street1: address1.text!, street2: address2.text!, city: city.text!, state: state.text!, postalCode: postalCode.text!, country: country.text!)
          User.imageToSend!.imageLink = imageURL
        }
        clearAndGo()
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        if (isSubmitAllowed())
        {
            let fn = "First Name: " + String(firstName.text ?? "" )
            let ln = "\nLast Name: " + String(lastName.text ?? "" )
            let a1 = "\nAddress 1: " + String(address1.text ?? "" )
            let a2 = "\nAddress 2: " + String(address2.text ?? "" )
            let cs = "\nCity: " + String(city.text ?? "" ) + "\nState: " + String(state.text ?? "" )
            let pc = "\nPostal Code: " + String(postalCode.text ?? "" ) + "\nCountry: " + String(country.text ?? "" )
            let msg =  fn + ln +  a1 + a2 + cs + pc
            let alert = UIAlertController(title: "Confirm Shipping Address", message: msg, preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Looks Good!", style: .default, handler: { action in
               self.addressIsConfirmed()
                   }))
            alert.addAction(UIAlertAction(title: "Edit", style: .cancel, handler:nil))
            self.present(alert, animated: true)
            
        } else
        {
            let alert = UIAlertController(title: "Ooops!", message: "Please enter a valid mailing address", preferredStyle: UIAlertController.Style.alert)
                     // add an action (button)
                     alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                     // show the alert
                     self.present(alert, animated: true, completion: nil)
                return
        }
    }
    
    @IBAction func skipPressed(_ sender: Any) {
        let image = extractImage()
        var imageURL = ""
        if image != nil {
          imageURL = AWS.uploadImage(image: image!, email: User.email, tag: "snapshot")
        }
        try! RealmConnection.realmAtlas!.write {
          User.imageToSend!.userContact?.firstName = "Skippy"
          User.imageToSend!.imageLink = imageURL
        }
      clearAndGo()
    }
    
    func clearAndGo() {
        try! RealmConnection.realm!.write {
          CurrentTool.reset()
          // Delete all of the Realm drawing objects
          RealmConnection.realm!.delete(RealmConnection.realm!.objects(LinkedPoint.self))
          RealmConnection.realm!.delete(RealmConnection.realm!.objects(Shape.self))
        }
        
        // Move to the Thank You view
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ThanksViewController") as? ThanksViewController
        self.navigationController!.pushViewController(vc!, animated: true)
    }
}


