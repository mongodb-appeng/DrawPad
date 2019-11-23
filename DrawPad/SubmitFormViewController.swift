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
    
    @IBAction func submitPressed(_ sender: Any) {
//        let userContact: UserContact = UserContact(firstName: firstName.text!, lastName: lastName.text!, email: User.email, street1: address1.text!, street2: address2.text!, city: city.text!, state: state.text!, postalCode: postalCode.text!, country: country.text!)
        try! RealmConnection.realmAtlas!.write {
          User.imageToSend!.userContact!.setUser(firstName: firstName.text!, lastName: lastName.text!, email: User.email, street1: address1.text!, street2: address2.text!, city: city.text!, state: state.text!, postalCode: postalCode.text!, country: country.text!)
        }
        clearAndGo()
    }
    
    @IBAction func skipPressed(_ sender: Any) {
        try! RealmConnection.realmAtlas!.write {
            User.imageToSend!.userContact?.firstName = "Skippy"
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


