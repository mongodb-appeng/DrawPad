/// Copyright (c) 2019 MongoDB Inc
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import RealmSwift

class ViewController: UIViewController, SettingsViewControllerDelegate, UITextFieldDelegate {
  @IBOutlet weak var mainImageView: UIImageView!
  @IBOutlet weak var tempImageView: UIImageView!
  @IBOutlet weak var hiddenTextField: UITextField!
  
//  let realm: Realm // TODO Remove
  var shapes: Results<Shape>
  let storedImages: Results<StoredImage>
  var notificationToken: NotificationToken!

  var lastPoint = CGPoint.zero
  var color = UIColor.black
  var brushWidth: CGFloat = 10.0
  var opacity: CGFloat = 1.0
  var swiped = false

  private var shapeType: ShapeType = .line
  private var currentShape: Shape?
  private var lineCount = 0
  
  required init?(coder aDecoder: NSCoder) {
    RealmConnection.connect()
//    let config = SyncUser.current?.configuration(realmURL: Constants.REALM_URL,
//       fullSynchronization: true)
//    self.realm = try! Realm(configuration: config!)
    self.shapes = RealmConnection.realm!.objects(Shape.self)
    self.storedImages = RealmConnection.realm!.objects(StoredImage.self).sorted(byKeyPath: "timestamp", ascending: true)
    super.init(coder: aDecoder)
  }

  private func draw(_ block: (CGContext) -> Void) {
//    UIGraphicsBeginImageContext(self.view.frame.size)
    UIGraphicsBeginImageContext(self.tempImageView.frame.size)
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }
//    self.tempImageView.image?.draw(in: self.view.bounds)
    self.tempImageView.image?.draw(in: tempImageView.bounds)

    block(context)

    self.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    notificationToken = shapes.observe { [weak self] changes in
      guard let strongSelf = self else {
        return
      }
      self!.hiddenTextField.delegate = self
      switch changes {
      case .initial(let shapes):
        strongSelf.draw { context in
          shapes.forEach { $0.draw(context) }
        }
        break
      case .update(let shapes, let deletions, let insertions, let modifications):
        
        (insertions + modifications).forEach { index in
          if shapes[index].deviceId != thisDevice {
            strongSelf.draw { context in
              let shape = shapes[index]
              shape.draw(context)
            }
          }
        }
        if deletions.count > 0 {
          strongSelf.mainImageView.image = nil
          strongSelf.shapes.forEach { shape in
            strongSelf.draw { context in
              shape.draw(context)
            }
          }
        }
        
        strongSelf.mergeViews()
        break
      case .error(let error):
        fatalError(error.localizedDescription)
      }
    }
  }
  
  deinit {
    notificationToken?.invalidate()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    print("In ViewController")
    guard let navController = segue.destination as? UINavigationController,
      let settingsController = navController.topViewController as? SettingsViewController else {
        return
    }
    settingsController.delegate = self
    settingsController.brush = brushWidth
    settingsController.opacity = opacity
    
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: nil)
    settingsController.red = red
    settingsController.green = green
    settingsController.blue = blue
  }
  
  // MARK: - Actions
  
  @IBAction func resetPressed(_ sender: Any) {
    mainImageView.image = nil

    try! RealmConnection.realm!.write {
      RealmConnection.realm!.delete(RealmConnection.realm!.objects(LinkedPoint.self))
      RealmConnection.realm!.delete(RealmConnection.realm!.objects(Shape.self))
    }
  }
  
  // TODO remove
  @IBAction func sharePressed(_ sender: Any) {
    guard let image = extractImage() else {
      print("Failed to extract image")
      return
    }
    let storedImage = StoredImage(image: image)
    try! RealmConnection.realm!.write {
      RealmConnection.realm!.add(storedImage)
    }

    let imageURL = AWS.uploadImage(image: image, email: "andrewjamesmorgan@gmail.com")
//    print("url: \(imageURL)")
    if imageURL != "" {
      try! RealmConnection.realm!.write {
        storedImage.imageLink = imageURL
      }
      let alertController = UIAlertController(title: "Uploaded Image", message:
          imageURL, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
      self.present(alertController, animated: true, completion: nil)
    } else {
      print("Failed to upload the image to S3")
    }
  }
  
  @IBAction func pencilPressed(_ sender: UIButton) {
    guard let pencil = Pencil(tag: sender.tag) else {
      return
    }
    color = pencil.color
    if pencil == .eraser {
      color = .white
    }
  }
  
  func extractImage() -> Data? {
    guard let image = mainImageView.image!.jpegData(compressionQuality: 1) else {
      print("Failed to get to the image")
      return nil
    }
    return image
  }
  
  func mergeViews() {
    // Merge tempImageView into mainImageView
    UIGraphicsBeginImageContext(mainImageView.frame.size)
    mainImageView.image?.draw(in: mainImageView.bounds, blendMode: .normal, alpha: 1.0)
    tempImageView?.image?.draw(in: tempImageView.bounds, blendMode: .normal, alpha: opacity)
    mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    tempImageView.image = nil
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
   
    currentShape = Shape()
    currentShape!.shapeType = shapeType
    currentShape!.color = color.toHex
    currentShape!.brushWidth = brushWidth

    if shapeType == .line {
      try! RealmConnection.realm!.write {
        RealmConnection.realm!.add(currentShape!)
      }
    }

    swiped = false
    
    try! RealmConnection.realm!.write {
      currentShape!.append(point: LinkedPoint(touch.location(in: tempImageView)))
    }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    
    let currentPoint = touch.location(in: tempImageView)

    draw { context in
      switch shapeType {
        // if the shape is a line, simply append the current point to the head of the list
      case .line:
        try! RealmConnection.realm!.write {
          currentShape!.append(point: LinkedPoint(currentPoint))
        }
        // if the shape is a rect or an ellipse, replace the head of the list
        // with the dragged point. the LinkedPoint list should always contain
        // (x₁, y₁) and (x₂, y₂), the top left and and bottom right corners
        // of the rect
      case .rect, .ellipse, .stamp, .text:
        // if 'swiped' (a.k.a. not a single point), erase the current shape,
        // which is effectively acting as a draft. then redraw the current
        // state
        if swiped {
          self.mainImageView.image = nil
          self.shapes.forEach { $0.draw(context) }
        }
        try! RealmConnection.realm!.write {
          currentShape!.replaceHead(point: LinkedPoint(currentPoint))
        }
        // if the shape is a triangle, have the original point be the tail
        // of the list, the 2nd point being where the current touch is,
        // and the 3rd point (x₁ - (x₂ - x₁), y₂)
      case .triangle:
        // if 'swiped' (a.k.a. not a single point), erase the current shape,
        // which is effectively acting as a draft. then redraw the current
        // state
        if swiped {
          self.mainImageView.image = nil
          self.shapes.forEach { $0.draw(context) }
        }
        try! RealmConnection.realm!.write {
          let point2 = LinkedPoint(currentPoint)
          currentShape!.lastPoint?.nextPoint = point2

          let point3 = LinkedPoint()
          point3.y = point2.y
          point3.x = currentShape!.lastPoint!.x - (point2.x - currentShape!.lastPoint!.x)
          point2.nextPoint = point3
        }
      }

      currentShape!.draw(context)
    }

    mergeViews()

    swiped = true
    lastPoint = currentPoint
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if !swiped {
      // draw a single point
      draw { context in
        currentShape!.draw(context)
      }
    }
    
    switch shapeType {
    case .line:
      mergeViews()
    case .text:
      // The bounding rectangle for the text has been created but the user
      // must now type in their text
      hiddenTextField.becomeFirstResponder()
      // The text shape will be stored and merged after the user hits return
    default:
      // if the shape is not a line, it exists in a draft state.
      // add it to the realm now
      // TODO: move the "draft" business logic out of the view
      if shapeType != .line {
        try! RealmConnection.realm!.write {
          RealmConnection.realm!.add(currentShape!)
        }
      }
      mergeViews()
    }
  }

  func settingsViewControllerFinished(_ settingsViewController: SettingsViewController) {
    brushWidth = settingsViewController.brush
    opacity = settingsViewController.opacity
    color = UIColor(red: settingsViewController.red,
                    green: settingsViewController.green,
                    blue: settingsViewController.blue,
                    alpha: opacity)
    dismiss(animated: true)
  }

  @IBAction func undo(_ sender: Any) {
    guard shapes.count > 0 else {
        return
    }

    draw { context in
      // find the last non-erased shape associated with this device Id.
      // then erase it, mark it as erased, and redraw the history of the drawing
      guard let shape = shapes.last(where: { $0.deviceId == thisDevice }) else {
        return
      }
      try! RealmConnection.realm!.write { RealmConnection.realm!.delete(shape) }
      shapes.forEach { $0.draw(context) }
    }

    currentShape = nil
  }

  // MARK: - Shape UI controls

  @IBAction func rectangleButtonTouched(_ sender: UIButton) {
    if shapeType == .rect {
      sender.isSelected = false
      shapeType = .line
    } else {
      sender.isSelected = true
      shapeType = .rect
    }
  }

  @IBAction func ellipsisButtonTouched(_ sender: UIButton) {
    if shapeType == .ellipse {
      sender.isSelected = false
      shapeType = .line
    } else {
      sender.isSelected = true
      shapeType = .ellipse
    }
  }
  
  @IBAction func triangleButtonTouched(_ sender: UIButton) {
    if shapeType == .triangle {
      sender.isSelected = false
      shapeType = .line
    } else {
      sender.isSelected = true
      shapeType = .triangle
    }
  }

  @IBAction func stampButtonTouched(_ sender: UIButton) {
    if shapeType == .stamp {
      sender.isSelected = false
      shapeType = .line
    } else {
      sender.isSelected = true
      shapeType = .stamp
    }
  }
  @IBAction func textButtonTouched(_ sender: UIButton) {
    if shapeType == .text {
      sender.isSelected = false
      shapeType = .line
    } else {
      sender.isSelected = true
      shapeType = .text
    }
  }
  
  @IBAction func logoutButtonTouched(_ sender: Any) {
    let user = SyncUser.current!
    user.logOut()
    self.navigationController!.popViewController(animated: true)
  }
  
  
  // Delegate methods
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if string == "\n" {
      hiddenTextField.text = ""
      hiddenTextField.resignFirstResponder()
      try! RealmConnection.realm!.write {
        RealmConnection.realm!.add(currentShape!)
      }
      mergeViews()
      draw { context in
        shapes.forEach { $0.draw(context) }
      }
      return false
    }
    var newText = textField.text ?? ""
    newText += string
    self.draw { context in
      mainImageView.image = nil
      shapes.forEach { $0.draw(context) }
      currentShape!.text = newText
      currentShape!.draw(context)
    }
    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    print("Started editing")
  }

}
