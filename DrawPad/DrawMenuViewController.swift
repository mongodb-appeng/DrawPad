//
//  DrawMenuViewController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit

class DrawMenuViewController: UIViewController {
    @IBOutlet weak var textButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
  func extractImage(viewController vc: ViewController) -> Data? {
      let vc = self.parent as! ViewController
      
      guard let image = vc.mainImageView.image?.jpegData(compressionQuality: 1) else {
        print("Failed to get to the image")
        return nil
      }
      return image
    }

    @IBAction func textPressed(_ sender: Any) {
        CurrentTool.shapeType = .text
    }
    
    @IBAction func drawingDonePressed(_ sender: Any) {
      print("drawingDonePressed")
      let vc = self.parent as! ViewController

      // TODO Push to the submit VC
      guard let image = extractImage(viewController: vc) else {
        print("Failed to extract image")
        return
      }
      let storedImage = StoredImage(image: image)
      storedImage.userContact?.email = User.email
      let imageURL = AWS.uploadImage(image: image, email: User.email)
      if imageURL != "" {
        storedImage.imageLink = imageURL
      } else {
              print("Failed to upload the image to S3")
      }
      
      try! RealmConnection.realmAtlas!.write {
        RealmConnection.realmAtlas!.add(storedImage)
        User.imageToSend = storedImage
      }

      let submitVC = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SubmitFormViewController") as? SubmitFormViewController
      self.navigationController!.pushViewController(submitVC!, animated: true)
    }
}
