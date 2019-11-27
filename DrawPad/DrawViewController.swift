////////////////////////////////////////////////////////////////////////////
//
// Copyright 2019 MongoDB Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import UIKit
import RealmSwift

extension UIImage {
  func resized(withPercentage percentage: CGFloat) -> UIImage? {
    let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
    return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
      _ in draw(in: CGRect(origin: .zero, size: canvas))
    }
  }
}

class DrawViewController: BaseViewController, UITextFieldDelegate {

  // MARK: - OUTLETS
  
  @IBOutlet weak var mainImageView: UIImageView!
  @IBOutlet weak var tempImageView: UIImageView!
  @IBOutlet weak var hiddenTextField: UITextField!
  
  @IBOutlet weak var pencilButton: DrawToolbarPersistedButton!
  @IBOutlet weak var leftToolbarParent: UIView!
  @IBOutlet weak var drawToolbar: DrawToolbarStackView!
  @IBOutlet weak var parentGridHorizontalStackView: UIStackView!
  @IBOutlet weak var scribbleButton: DrawToolbarPopoverButton!
  @IBOutlet weak var sansSerifButton: DrawToolbarPopoverButton!
  @IBOutlet weak var opacityButton: DrawToolbarPopoverButton!
  @IBOutlet weak var stampButton: DrawToolbarPopoverButton!
  
  @IBOutlet weak var rectangleButton: DrawToolbarPersistedButton!
  @IBOutlet weak var ovalButton: DrawToolbarPersistedButton!
  @IBOutlet weak var triangleButton: DrawToolbarPersistedButton!

  // MARK: - INIT
  let scribblePopoverParent = UIView()
  let scribblePopoverToolbar = DrawToolbarStackView()
  let sansSerifPopoverParent = UIView()
  let sansSerifPopoverToolbar = DrawToolbarStackView()
  let stampsPopoverParent = UIView()
  let stampsPopoverToolbar = DrawToolbarStackView()
  let opacityPopoverParent = UIView()
  let opacityPopoverToolbar = DrawToolbarStackView()
  let rectanglePopoverParent = UIView()
  let rectanglePopoverToolbar = DrawToolbarStackView()
  let ovalPopoverParent = UIView()
  let ovalPopoverToolbar = DrawToolbarStackView()
  let trianglePopoverParent = UIView()
  let trianglePopoverToolbar = DrawToolbarStackView()
  var popoverParents: [UIView] = []
  
  var shapes: Results<Shape>
  let storedImages: Results<StoredImage>
  var notificationToken: NotificationToken!
  var lastPoint = CGPoint.zero
  var swiped = false
  private var currentShape: Shape?
  private var lineCount = 0

  required init?(coder aDecoder: NSCoder) {
    RealmConnection.connect()
    self.shapes = RealmConnection.realm!.objects(Shape.self)
    self.storedImages = RealmConnection.realmAtlas!.objects(StoredImage.self).sorted(byKeyPath: "timestamp", ascending: true)
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    popoverParents = [scribblePopoverParent, sansSerifPopoverParent, stampsPopoverParent, opacityPopoverParent, rectanglePopoverParent, ovalPopoverParent, trianglePopoverParent]
    pencilButton.select()
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
  // MARK: - BUSINESS LOGIC
  func mergeViews() {
    // Merge tempImageView into mainImageView
    UIGraphicsBeginImageContext(mainImageView.frame.size)
    mainImageView.image?.draw(in: mainImageView.bounds, blendMode: .normal, alpha: 1.0)
    tempImageView?.image?.draw(in: tempImageView.bounds, blendMode: .normal, alpha: 1.0)
    mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    tempImageView.image = nil
  }
  
  private func draw(_ block: (CGContext) -> Void) {
    UIGraphicsBeginImageContext(self.tempImageView.frame.size)
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }
    self.tempImageView.image?.draw(in: tempImageView.bounds)

    block(context)

    self.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
  }
  
  func extractImage() -> Data? {
    
    // The image must be extracted as a JPEG (not a PNG) or else erased conent will
    // show as white on a transparent background
    guard let image = mainImageView.image?.jpegData(compressionQuality: 1.0) else {
      print("Failed to get to the image")
        return nil
      }
    return image
//    guard let rawImage = mainImageView.image,
//      let resizedImage = rawImage.resized(withPercentage: 0.5),
//      let imageData = resizedImage.pngData() else {
//      print("Failed to get to the image")
//      return nil
//    }
//
//    return imageData
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
   
    currentShape = Shape()
    currentShape!.shapeType = CurrentTool.shapeType
    currentShape!.color = CurrentTool.color.toHex
    currentShape!.brushWidth = CurrentTool.brushWidth
    currentShape!.fontStyle = CurrentTool.fontStyle
    currentShape!.filled = CurrentTool.filled
    if CurrentTool.shapeType == ShapeType.stamp {
      currentShape!.stampFIle = CurrentTool.stampFile
    }

    if CurrentTool.shapeType == .line {
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
      switch CurrentTool.shapeType {
        // if the shape is a line, simply append the current point to the head of the list
      case .line:
        try! RealmConnection.realm!.write {
          currentShape!.append(point: LinkedPoint(currentPoint))
        }
        // if the shape is a rect or an ellipse, replace the head of the list
        // with the dragged point. the LinkedPoint list should always contain
        // (x₁, y₁) and (x₂, y₂), the top left and and bottom right corners
        // of the rect
      case .rect, .ellipse, .stamp, .text, .straightLine:
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
    
    switch CurrentTool.shapeType {
    // TODO - REMOVE
    //    case .line:
    //      mergeViews()
    case .text:
      // The bounding rectangle for the text has been created but the user
      // must now type in their text
      hiddenTextField.becomeFirstResponder()
      // The text shape will be stored and merged after the user hits return
    default:
      // if the shape is not a line, it exists in a draft state.
      // add it to the realm now
      // TODO: move the "draft" business logic out of the view
      if CurrentTool.shapeType != .line {
        try! RealmConnection.realm!.write {
          RealmConnection.realm!.add(currentShape!)
        }
      }
      mergeViews()
    }
  }

  // MARK: - DELEGATES
  
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
  
  // MARK: - ACTIONS
//ZXZX
  @IBAction func straightLineTapped(_ sender: Any) {
    
  }
  
  @IBAction func toolbarButtonTapped(_ sender: UIButton) {
    print("Main toolbar button tapped")
    if let button = sender as? DrawToolbarPersistedButton {
      self.drawToolbar.clearCurrentButtonSelection()
      button.select()
    }
  }

  @objc func scribblePopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary scribble toolbar tap")
    scribblePopoverToolbar.clearCurrentButtonSelection()
  }

  @objc func sansSerifPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary sans serif toolbar tap")
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.shapeType = .text
  }

  @objc func stampsPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary stamps toolbar tap")
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.shapeType = .stamp
  }
  
  @objc func rectanglePopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary rectangle toolbar tap")
    rectanglePopoverToolbar.clearCurrentButtonSelection()
  }
  
  @objc func rectangleFilledTapped(sender: UIButton) {
    print("Secondary rectangle filled toolbar tap")
    rectanglePopoverToolbar.clearCurrentButtonSelection()
    rectanglePopoverToolbar.savedSelection = 0
    rectangleButton.setImage(UIImage(named: "RectangleFilled.pdf"), for: .normal)
    CurrentTool.filled = true
  }
  
  @objc func rectangleEmptyTapped(sender: UIButton) {
    print("Secondary rectangle empty toolbar tap")
    rectanglePopoverToolbar.clearCurrentButtonSelection()
    rectanglePopoverToolbar.savedSelection = 1
    rectangleButton.setImage(UIImage(named: "Rectangle.pdf"), for: .normal)
    CurrentTool.filled = false
  }
  
  @objc func ovalPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary oval toolbar tap")
    ovalPopoverToolbar.clearCurrentButtonSelection()
  }
  
  @objc func ovalFilledTapped(sender: UIButton) {
    print("Secondary oval filled toolbar tap")
    ovalPopoverToolbar.clearCurrentButtonSelection()
    ovalPopoverToolbar.savedSelection = 0
    ovalButton.setImage(UIImage(named: "OvalFilled.pdf"), for: .normal)
    CurrentTool.filled = true
  }
  
  @objc func ovalEmptyTapped(sender: UIButton) {
    print("Secondary oval empty toolbar tap")
    ovalPopoverToolbar.clearCurrentButtonSelection()
    ovalPopoverToolbar.savedSelection = 1
    ovalButton.setImage(UIImage(named: "Oval.pdf"), for: .normal)
    CurrentTool.filled = false
  }
  
  @objc func trianglePopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary triangle toolbar tap")
    trianglePopoverToolbar.clearCurrentButtonSelection()
  }
  
  @objc func triangleFilledTapped(sender: UIButton) {
    print("Secondary triangle filled toolbar tap")
    trianglePopoverToolbar.clearCurrentButtonSelection()
    trianglePopoverToolbar.savedSelection = 0
    triangleButton.setImage(UIImage(named: "TriangleFilled.pdf"), for: .normal)
    CurrentTool.filled = true
  }
  
  @objc func triangleEmptyTapped(sender: UIButton) {
    print("Secondary triangle empty toolbar tap")
    trianglePopoverToolbar.clearCurrentButtonSelection()
    trianglePopoverToolbar.savedSelection = 1
    triangleButton.setImage(UIImage(named: "Triangle.pdf"), for: .normal)
    CurrentTool.filled = false
  }
  
  @objc func opacityPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
  }
  
  @objc func opacityBlackTapped(sender: UIButton) {
    print("Secondary Black opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
    opacityPopoverToolbar.savedSelection = 0
    opacityButton.setImage(UIImage(named: "shade100.pdf"), for: .normal)
    guard let pencil = Pencil(tag: 1) else {
      return
    }
    CurrentTool.color = pencil.color
  }

  @objc func opacityDarkestTapped(sender: UIButton) {
    print("Secondary Darkest Grey opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
    opacityPopoverToolbar.savedSelection = 1
    opacityButton.setImage(UIImage(named: "shade70.pdf"), for: .normal)
    guard let pencil = Pencil(tag: 2) else {
      return
    }
    CurrentTool.color = pencil.color
  }

  @objc func opacityMidTapped(sender: UIButton) {
    print("Secondary Mid Grey opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
    opacityPopoverToolbar.savedSelection = 2
    opacityButton.setImage(UIImage(named: "shade50.pdf"), for: .normal)
    guard let pencil = Pencil(tag: 3) else {
      return
    }
    CurrentTool.color = pencil.color
  }
  
  @objc func opacityLightestTapped(sender: UIButton) {
    print("Secondary Lightest Grey opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
    opacityPopoverToolbar.savedSelection = 3
    opacityButton.setImage(UIImage(named: "shade30.pdf"), for: .normal)
    guard let pencil = Pencil(tag: 4) else {
      return
    }
    CurrentTool.color = pencil.color
  }
 
  @objc func secondaryToolbarButtonTapped(sender: DrawToolbarPersistedButton) {
    print("Secondary button tap")
    sender.select()
    clearSecondaryPopovers(except: nil)
  }

  // MARK: - PRIMARY TOOLBAR TAP HANDLDERS

  @IBAction func finishButtonTapped(_ sender: UIButton) {
    print("Finish button tapped")
    guard let image = extractImage() else {
      print("Failed to extract image")
      return
    }
    print("Drawing to be uploaded is \(image.count / 1000)kb")
    let storedImage = StoredImage(image: image)
    storedImage.userContact?.email = User.email
    
    try! RealmConnection.realmAtlas!.write {
      RealmConnection.realmAtlas!.add(storedImage)
      User.imageToSend = storedImage
    }

    let submitVC = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SubmitFormViewController") as? SubmitFormViewController
    submitVC?.drawing = mainImageView.image
    self.navigationController!.pushViewController(submitVC!, animated: true)
  }
//   @IBAction func finishButtonTapped(_ sender: UIButton) {
//  print("Finish button tapped")
//  guard let image = extractImage() else {
//    print("Failed to extract image")
//    return
//  }
//  let storedImage = StoredImage(image: image)
//  storedImage.userContact?.email = User.email
//  let imageURL = AWS.uploadImage(image: image, email: User.email)
//  if imageURL != "" {
//    storedImage.imageLink = imageURL
//  } else {
//          print("Failed to upload the image to S3")
//  }
//
//  try! RealmConnection.realmAtlas!.write {
//    RealmConnection.realmAtlas!.add(storedImage)
//    User.imageToSend = storedImage
//  }
//
//  let submitVC = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SubmitFormViewController") as? SubmitFormViewController
//  submitVC?.drawing = UIImage(data: image)
//  self.navigationController!.pushViewController(submitVC!, animated: true)
//}
  
  
  @IBAction func undoButtonTapped(_ sender: UIButton) {
    print("Undo button tapped")
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

  @IBAction func pencilButtonTapped(_ sender: UIButton) {
    print("Pencil button tapped")
    clearSecondaryPopovers(except: nil)
    CurrentTool.shapeType = .line
    CurrentTool.color = .black
  }

  @IBAction func scribbleButtonTapped(_ sender: UIButton) {
    print("Scribble button tapped")
    clearSecondaryPopovers(except: [scribblePopoverParent])
    if scribblePopoverParent.isDescendant(of: self.view) {
      return
    }
    scribblePopoverParent.backgroundColor = UIColor(red: 48/255, green: 52/255, blue: 52/255, alpha: 1)
    self.view.addSubview(scribblePopoverParent)
    scribblePopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = scribblePopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = scribblePopoverParent.topAnchor.constraint(equalTo: scribbleButton.topAnchor, constant: 0)
    let widthConstraint = scribblePopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = scribblePopoverParent.heightAnchor.constraint(equalTo: scribbleButton.heightAnchor, multiplier: 3)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    scribblePopoverToolbar.axis = .vertical
    scribblePopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(scribblePopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    scribblePopoverToolbar.addGestureRecognizer(tapGesture)

    let scribbleLightImage = UIImage(named: "line_thin.pdf")
    let scribbleLightButton = DrawToolbarPersistedButton(image: scribbleLightImage!)
    scribbleLightButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.addTarget(self, action: #selector(scribbleLightTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.tintColor = .white

    let scribbleMediumImage = UIImage(named: "line_med.pdf")
    let scribbleMediumButton = DrawToolbarPersistedButton(image: scribbleMediumImage!)
    scribbleMediumButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleMediumButton.addTarget(self, action: #selector(scribbleMediumTapped(sender:)), for: .touchUpInside)
    scribbleMediumButton.tintColor = .white

    let scribbleHeavyImage = UIImage(named: "line_fat.pdf")
    let scribbleHeavyButton = DrawToolbarPersistedButton(image: scribbleHeavyImage!)
    scribbleHeavyButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleHeavyButton.addTarget(self, action: #selector(scribbleHeavyTapped(sender:)), for: .touchUpInside)
    scribbleHeavyButton.tintColor = .white

    scribblePopoverToolbar.addArrangedSubview(scribbleLightButton)
    scribblePopoverToolbar.addArrangedSubview(scribbleMediumButton)
    scribblePopoverToolbar.addArrangedSubview(scribbleHeavyButton)
    scribblePopoverParent.addSubview(scribblePopoverToolbar)
    scribblePopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = scribblePopoverToolbar.leadingAnchor.constraint(equalTo: scribblePopoverParent.leadingAnchor)
    let top = scribblePopoverToolbar.topAnchor.constraint(equalTo: scribblePopoverParent.topAnchor)
    let trailing = scribblePopoverToolbar.trailingAnchor.constraint(equalTo: scribblePopoverParent.trailingAnchor)
    let bottom = scribblePopoverToolbar.bottomAnchor.constraint(equalTo: scribblePopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = scribblePopoverToolbar.arrangedSubviews[scribblePopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
  }

  @IBAction func eraserButtonTapped(_ sender: UIButton) {
    print("Eraser button tapped")
    clearSecondaryPopovers(except: nil)
    CurrentTool.color = .white
  }

  @IBAction func textboxButtonTapped(_ sender: UIButton) {
    print("Textbox button tapped")
    CurrentTool.shapeType = .text
  }

  @IBAction func sansSerifButtonTapped(_ sender: UIButton) {
    print("Sans Serif button tapped")
    clearSecondaryPopovers(except: [sansSerifPopoverParent])
    if sansSerifPopoverParent.isDescendant(of: self.view) {
      return
    }

    CurrentTool.shapeType = .text
    
    sansSerifPopoverParent.backgroundColor = UIColor(red: 48/255, green: 52/255, blue: 52/255, alpha: 1)
    self.view.addSubview(sansSerifPopoverParent)
    sansSerifPopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = sansSerifPopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = sansSerifPopoverParent.topAnchor.constraint(equalTo: sansSerifButton.topAnchor, constant: 0)
    let widthConstraint = sansSerifPopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = sansSerifPopoverParent.heightAnchor.constraint(equalTo: sansSerifButton.heightAnchor, multiplier: 3)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    sansSerifPopoverToolbar.axis = .vertical
    sansSerifPopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sansSerifPopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    sansSerifPopoverToolbar.addGestureRecognizer(tapGesture)

//    let sansSerifNormalImage = UIImage(systemName: "textbox")
//    let sansSerifNormalButton = DrawToolbarPersistedButton(image: sansSerifNormalImage!)
    let sansSerifNormalButton = DrawToolbarPersistedButton(label: "Helvetica")
    sansSerifNormalButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    sansSerifNormalButton.addTarget(self, action: #selector(sansSerifNormalTapped(sender:)), for: .touchUpInside)
    sansSerifNormalButton.tintColor = .white

//    let sansSerifSerifImage = UIImage(systemName: "textbox")
//    let sansSerifSerifButton = DrawToolbarPersistedButton(image: sansSerifSerifImage!)
    let sansSerifSerifButton = DrawToolbarPersistedButton(label: "Type")
    sansSerifSerifButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    sansSerifSerifButton.addTarget(self, action: #selector(sansSerifSerifTapped(sender:)), for: .touchUpInside)
    sansSerifSerifButton.tintColor = .white

//    let sansSerifMonoImage = UIImage(systemName: "textbox")
//    let sansSerifMonoButton = DrawToolbarPersistedButton(image: sansSerifMonoImage!)
    let sansSerifMonoButton = DrawToolbarPersistedButton(label: "Marker")
    sansSerifMonoButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    sansSerifMonoButton.addTarget(self, action: #selector(sansSerifMonoTapped(sender:)), for: .touchUpInside)
    sansSerifMonoButton.tintColor = .white

    sansSerifPopoverToolbar.addArrangedSubview(sansSerifNormalButton)
    sansSerifPopoverToolbar.addArrangedSubview(sansSerifSerifButton)
    sansSerifPopoverToolbar.addArrangedSubview(sansSerifMonoButton)
    sansSerifPopoverParent.addSubview(sansSerifPopoverToolbar)
    sansSerifPopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = sansSerifPopoverToolbar.leadingAnchor.constraint(equalTo: sansSerifPopoverParent.leadingAnchor)
    let top = sansSerifPopoverToolbar.topAnchor.constraint(equalTo: sansSerifPopoverParent.topAnchor)
    let trailing = sansSerifPopoverToolbar.trailingAnchor.constraint(equalTo: sansSerifPopoverParent.trailingAnchor)
    let bottom = sansSerifPopoverToolbar.bottomAnchor.constraint(equalTo: sansSerifPopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])
    if let selectedButton = sansSerifPopoverToolbar.arrangedSubviews[sansSerifPopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
  }
  
  @objc func sansSerifNormalTapped(sender: UIButton) {
    print("Secondary Text normal toolbar tap")
    sansSerifPopoverToolbar.savedSelection = 0
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.fontStyle = .normal
//    sansSerifButton.setTitle("Sans Serif", for: .normal)
    clearSecondaryPopovers(except: nil)
  }

  @objc func sansSerifSerifTapped(sender: UIButton) {
    print("Secondary Text serif toolbar tap")
    sansSerifPopoverToolbar.savedSelection = 1
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.fontStyle = .serif
//    sansSerifButton.setTitle("Serif", for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func sansSerifMonoTapped(sender: UIButton) {
    print("Secondary Text mono toolbar tap")
    sansSerifPopoverToolbar.savedSelection = 2
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.fontStyle = .monospace
//    sansSerifButton.setTitle("Monospace", for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @IBAction func stampsButtonTapped(_ sender: UIButton) {
    print("Stamps button tapped")
    clearSecondaryPopovers(except: [stampsPopoverParent])

    if stampsPopoverParent.isDescendant(of: self.view) {
      return
    }

    stampsPopoverParent.backgroundColor = UIColor(red: 48/255, green: 52/255, blue: 52/255, alpha: 1)
    self.view.addSubview(stampsPopoverParent)
    stampsPopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = stampsPopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = stampsPopoverParent.topAnchor.constraint(equalTo: leftToolbarParent.topAnchor, constant: 0)
    let widthConstraint = stampsPopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let bottomConstraint = stampsPopoverParent.bottomAnchor.constraint(equalTo: leftToolbarParent.bottomAnchor, constant: 0)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, bottomConstraint])

    stampsPopoverToolbar.axis = .vertical
    stampsPopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(stampsPopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    stampsPopoverToolbar.addGestureRecognizer(tapGesture)

    // TODO: UPDATE VARIABLE NAMES AND IMAGES

//    let scribbleLightImage = UIImage(systemName: "scribble")
    let owlImage = UIImage(named: "owl.pdf")
    let owlButton = DrawToolbarPersistedButton(image: owlImage!)
    owlButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    owlButton.addTarget(self, action: #selector(stampOwlTapped(sender:)), for: .touchUpInside)
    owlButton.tintColor = .white

    let planetImage = UIImage(named: "planet.pdf")
    let planetButton = DrawToolbarPersistedButton(image: planetImage!)
    planetButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    planetButton.addTarget(self, action: #selector(stampPlanetTapped(sender:)), for: .touchUpInside)
    planetButton.tintColor = .white

    let eyeImage = UIImage(named: "eye.pdf")
    let eyeButton = DrawToolbarPersistedButton(image: eyeImage!)
    eyeButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    eyeButton.addTarget(self, action: #selector(stampEyeTapped(sender:)), for: .touchUpInside)
    eyeButton.tintColor = .white

    let arrowsImage = UIImage(named: "arrows.pdf")
    let arrowsButton = DrawToolbarPersistedButton(image: arrowsImage!)
    arrowsButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    arrowsButton.addTarget(self, action: #selector(stampArrowsTapped(sender:)), for: .touchUpInside)
    arrowsButton.tintColor = .white

    let leafImage = UIImage(named: "leaf_outline.pdf")
    let leafButton = DrawToolbarPersistedButton(image: leafImage!)
    leafButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    leafButton.addTarget(self, action: #selector(stampLeafTapped(sender:)), for: .touchUpInside)
    leafButton.tintColor = .white
    
    let databaseImage = UIImage(named: "database.pdf")
    let databaseButton = DrawToolbarPersistedButton(image: databaseImage!)
    databaseButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    databaseButton.addTarget(self, action: #selector(stampDatabaseTapped(sender:)), for: .touchUpInside)
    databaseButton.tintColor = .white
    
    let serverImage = UIImage(named: "server.pdf")
    let serverButton = DrawToolbarPersistedButton(image: serverImage!)
    serverButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    serverButton.addTarget(self, action: #selector(stampServerTapped(sender:)), for: .touchUpInside)
    serverButton.tintColor = .white
    
    let anchorImage = UIImage(named: "anchor.pdf")
    let anchorButton = DrawToolbarPersistedButton(image: anchorImage!)
    anchorButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    anchorButton.addTarget(self, action: #selector(stampAnchorTapped(sender:)), for: .touchUpInside)
    anchorButton.tintColor = .white
    
    let planet2Image = UIImage(named: "planet2.pdf")
    let planet2Button = DrawToolbarPersistedButton(image: planet2Image!)
    planet2Button.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    planet2Button.addTarget(self, action: #selector(stampPlanet2Tapped(sender:)), for: .touchUpInside)
    planet2Button.tintColor = .white
    
    let beachImage = UIImage(named: "beach.pdf")
    let beachButton = DrawToolbarPersistedButton(image: beachImage!)
    beachButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    beachButton.addTarget(self, action: #selector(stampBeachTapped(sender:)), for: .touchUpInside)
    beachButton.tintColor = .white
    
    let swordsImage = UIImage(named: "swords.pdf")
    let swordsButton = DrawToolbarPersistedButton(image: swordsImage!)
    swordsButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    swordsButton.addTarget(self, action: #selector(stampSwordsTapped(sender:)), for: .touchUpInside)
    swordsButton.tintColor = .white
    
    let diamondImage = UIImage(named: "diamond.pdf")
    let diamondButton = DrawToolbarPersistedButton(image: diamondImage!)
    diamondButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    diamondButton.addTarget(self, action: #selector(stampDiamondTapped(sender:)), for: .touchUpInside)
    diamondButton.tintColor = .white
    
    stampsPopoverToolbar.addArrangedSubview(owlButton)
    stampsPopoverToolbar.addArrangedSubview(planetButton)
    stampsPopoverToolbar.addArrangedSubview(eyeButton)
    stampsPopoverToolbar.addArrangedSubview(arrowsButton)
    stampsPopoverToolbar.addArrangedSubview(leafButton)
    stampsPopoverToolbar.addArrangedSubview(databaseButton)
    stampsPopoverToolbar.addArrangedSubview(serverButton)
    stampsPopoverToolbar.addArrangedSubview(anchorButton)
    stampsPopoverToolbar.addArrangedSubview(planet2Button)
    stampsPopoverToolbar.addArrangedSubview(beachButton)
    stampsPopoverToolbar.addArrangedSubview(swordsButton)
    stampsPopoverToolbar.addArrangedSubview(diamondButton)
    
    stampsPopoverParent.addSubview(stampsPopoverToolbar)
    stampsPopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = stampsPopoverToolbar.leadingAnchor.constraint(equalTo: stampsPopoverParent.leadingAnchor)
    let top = stampsPopoverToolbar.topAnchor.constraint(equalTo: stampsPopoverParent.topAnchor)
    let trailing = stampsPopoverToolbar.trailingAnchor.constraint(equalTo: stampsPopoverParent.trailingAnchor)
    let bottom = stampsPopoverToolbar.bottomAnchor.constraint(equalTo: stampsPopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = stampsPopoverToolbar.arrangedSubviews[stampsPopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
  }
   
  @objc func stampOwlTapped(sender: UIButton) {
    print("Secondary stamp owl toolbar tap")
    stampsPopoverToolbar.savedSelection = 0
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_owl.png"
    stampButton.setImage(UIImage(named: "owl.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }

  @objc func stampPlanetTapped(sender: UIButton) {
    print("Secondary stamp planet toolbar tap")
    stampsPopoverToolbar.savedSelection = 1
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_planet.png"
    stampButton.setImage(UIImage(named: "planet.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }

  @objc func stampEyeTapped(sender: UIButton) {
    print("Secondary stamp eye toolbar tap")
    stampsPopoverToolbar.savedSelection = 2
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_eye.png"
    stampButton.setImage(UIImage(named: "eye.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func stampArrowsTapped(sender: UIButton) {
    print("Secondary stamp arrows toolbar tap")
    stampsPopoverToolbar.savedSelection = 3
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_arrows.png"
    stampButton.setImage(UIImage(named: "arrows.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func stampLeafTapped(sender: UIButton) {
    print("Secondary stamp leaf toolbar tap")
    stampsPopoverToolbar.savedSelection = 4
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_leaf_outline.png"
    stampButton.setImage(UIImage(named: "leaf_outline.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }

  @objc func stampDatabaseTapped(sender: UIButton) {
    print("Secondary stamp database toolbar tap")
    stampsPopoverToolbar.savedSelection = 5
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_database.png"
    stampButton.setImage(UIImage(named: "database.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func stampServerTapped(sender: UIButton) {
    print("Secondary stamp server toolbar tap")
    stampsPopoverToolbar.savedSelection = 6
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_server.png"
    stampButton.setImage(UIImage(named: "server.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func stampAnchorTapped(sender: UIButton) {
    print("Secondary stamp anchor toolbar tap")
    stampsPopoverToolbar.savedSelection = 7
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_anchor.png"
    stampButton.setImage(UIImage(named: "anchor.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func stampPlanet2Tapped(sender: UIButton) {
    print("Secondary stamp planet2 toolbar tap")
    stampsPopoverToolbar.savedSelection = 8
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_planet2.png"
    stampButton.setImage(UIImage(named: "planet2.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func stampBeachTapped(sender: UIButton) {
    print("Secondary stamp beach toolbar tap")
    stampsPopoverToolbar.savedSelection = 9
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_beach.png"
    stampButton.setImage(UIImage(named: "beach.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func stampSwordsTapped(sender: UIButton) {
    print("Secondary stamp swords toolbar tap")
    stampsPopoverToolbar.savedSelection = 10
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_swords.png"
    stampButton.setImage(UIImage(named: "swords.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  
  @objc func stampDiamondTapped(sender: UIButton) {
    print("Secondary stamp diamond toolbar tap")
    stampsPopoverToolbar.savedSelection = 11
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.stampFile = "stamp_diamond.png"
    stampButton.setImage(UIImage(named: "diamond.pdf"), for: .normal)
    clearSecondaryPopovers(except: nil)
  }
  @IBAction func opacityButtonTapped(_ sender: UIButton) {
    print("Opacity button tapped")
    clearSecondaryPopovers(except: [opacityPopoverParent])

    if opacityPopoverParent.isDescendant(of: self.view) {
      return
    }

    opacityPopoverParent.backgroundColor = UIColor(red: 48/255, green: 52/255, blue: 52/255, alpha: 1)
    self.view.addSubview(opacityPopoverParent)
    opacityPopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = opacityPopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = opacityPopoverParent.topAnchor.constraint(equalTo: opacityButton.topAnchor, constant: 0)
    let widthConstraint = opacityPopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = opacityPopoverParent.heightAnchor.constraint(equalTo: opacityButton.heightAnchor, multiplier: 4)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    opacityPopoverToolbar.axis = .vertical
    opacityPopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(opacityPopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    opacityPopoverToolbar.addGestureRecognizer(tapGesture)

    let blackShadeImage = UIImage(named: "shade100.pdf")
    let blackShadeButton = DrawToolbarPersistedButton(image: blackShadeImage!)
    blackShadeButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    blackShadeButton.addTarget(self, action: #selector(opacityBlackTapped(sender:)), for: .touchUpInside)
    blackShadeButton.tintColor = .white

    let darkestShadeImage = UIImage(named: "shade70.pdf")
    let darkestShadeButton = DrawToolbarPersistedButton(image: darkestShadeImage!)
    darkestShadeButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    darkestShadeButton.addTarget(self, action: #selector(opacityDarkestTapped(sender:)), for: .touchUpInside)
    darkestShadeButton.tintColor = .white

    let midShadeImage = UIImage(named: "shade50.pdf")
    let midShadeButton = DrawToolbarPersistedButton(image: midShadeImage!)
    midShadeButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    midShadeButton.addTarget(self, action: #selector(opacityMidTapped(sender:)), for: .touchUpInside)
    midShadeButton.tintColor = .white

    let lightestShadeImage = UIImage(named: "shade30.pdf")
    let lightestShadeButton = DrawToolbarPersistedButton(image: lightestShadeImage!)
    lightestShadeButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    lightestShadeButton.addTarget(self, action: #selector(opacityLightestTapped(sender:)), for: .touchUpInside)
    lightestShadeButton.tintColor = .white

    opacityPopoverToolbar.addArrangedSubview(blackShadeButton)
    opacityPopoverToolbar.addArrangedSubview(darkestShadeButton)
    opacityPopoverToolbar.addArrangedSubview(midShadeButton)
    opacityPopoverToolbar.addArrangedSubview(lightestShadeButton)
    opacityPopoverParent.addSubview(opacityPopoverToolbar)
    opacityPopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = opacityPopoverToolbar.leadingAnchor.constraint(equalTo: opacityPopoverParent.leadingAnchor)
    let top = opacityPopoverToolbar.topAnchor.constraint(equalTo: opacityPopoverParent.topAnchor)
    let trailing = opacityPopoverToolbar.trailingAnchor.constraint(equalTo: opacityPopoverParent.trailingAnchor)
    let bottom = opacityPopoverToolbar.bottomAnchor.constraint(equalTo: opacityPopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = opacityPopoverToolbar.arrangedSubviews[opacityPopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
  }

  @IBAction func squareButtonTapped(_ sender: UIButton) {
    print("Square button tapped")
    clearSecondaryPopovers(except: [rectanglePopoverParent])

    if rectanglePopoverParent.isDescendant(of: self.view) {
      return
    }

    rectanglePopoverParent.backgroundColor = UIColor(red: 48/255, green: 52/255, blue: 52/255, alpha: 1)
    self.view.addSubview(rectanglePopoverParent)
    rectanglePopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = rectanglePopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = rectanglePopoverParent.topAnchor.constraint(equalTo: rectangleButton.topAnchor, constant: 0)
    let widthConstraint = rectanglePopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = rectanglePopoverParent.heightAnchor.constraint(equalTo: rectangleButton.heightAnchor, multiplier: 2)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    rectanglePopoverToolbar.axis = .vertical
    rectanglePopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(rectanglePopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    rectanglePopoverToolbar.addGestureRecognizer(tapGesture)

    let rectangleFilledImage = UIImage(named: "RectangleFilled.pdf")
    let rectangleFilledButton = DrawToolbarPersistedButton(image: rectangleFilledImage!)
    rectangleFilledButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    rectangleFilledButton.addTarget(self, action: #selector(rectangleFilledTapped(sender:)), for: .touchUpInside)
    rectangleFilledButton.tintColor = .white
    
    let rectangleImage = UIImage(named: "Rectangle.pdf")
    let rectangleButton = DrawToolbarPersistedButton(image: rectangleImage!)
    rectangleButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    rectangleButton.addTarget(self, action: #selector(rectangleEmptyTapped(sender:)), for: .touchUpInside)
    rectangleButton.tintColor = .white

    rectanglePopoverToolbar.addArrangedSubview(rectangleFilledButton)
    rectanglePopoverToolbar.addArrangedSubview(rectangleButton)
    rectanglePopoverParent.addSubview(rectanglePopoverToolbar)
    rectanglePopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = rectanglePopoverToolbar.leadingAnchor.constraint(equalTo: rectanglePopoverParent.leadingAnchor)
    let top = rectanglePopoverToolbar.topAnchor.constraint(equalTo: rectanglePopoverParent.topAnchor)
    let trailing = rectanglePopoverToolbar.trailingAnchor.constraint(equalTo: rectanglePopoverParent.trailingAnchor)
    let bottom = rectanglePopoverToolbar.bottomAnchor.constraint(equalTo: rectanglePopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = rectanglePopoverToolbar.arrangedSubviews[rectanglePopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
    CurrentTool.shapeType = .rect
  }

  @IBAction func circleButtonTapped(_ sender: UIButton) {
    print("Circle button tapped")
    clearSecondaryPopovers(except: [ovalPopoverParent])

    if ovalPopoverParent.isDescendant(of: self.view) {
      return
    }

    ovalPopoverParent.backgroundColor = UIColor(red: 48/255, green: 52/255, blue: 52/255, alpha: 1)
    self.view.addSubview(ovalPopoverParent)
    ovalPopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = ovalPopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = ovalPopoverParent.topAnchor.constraint(equalTo: ovalButton.topAnchor, constant: 0)
    let widthConstraint = ovalPopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = ovalPopoverParent.heightAnchor.constraint(equalTo: ovalButton.heightAnchor, multiplier: 2)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    ovalPopoverToolbar.axis = .vertical
    ovalPopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ovalPopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    ovalPopoverToolbar.addGestureRecognizer(tapGesture)

    let ovalFilledImage = UIImage(named: "OvalFilled.pdf")
    let ovalFilledButton = DrawToolbarPersistedButton(image: ovalFilledImage!)
    ovalFilledButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    ovalFilledButton.addTarget(self, action: #selector(ovalFilledTapped(sender:)), for: .touchUpInside)
    ovalFilledButton.tintColor = .white
    
    let ovalImage = UIImage(named: "Oval.pdf")
    let ovalButton = DrawToolbarPersistedButton(image: ovalImage!)
    ovalButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    ovalButton.addTarget(self, action: #selector(ovalEmptyTapped(sender:)), for: .touchUpInside)
    ovalButton.tintColor = .white

    ovalPopoverToolbar.addArrangedSubview(ovalFilledButton)
    ovalPopoverToolbar.addArrangedSubview(ovalButton)
    ovalPopoverParent.addSubview(ovalPopoverToolbar)
    ovalPopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = ovalPopoverToolbar.leadingAnchor.constraint(equalTo: ovalPopoverParent.leadingAnchor)
    let top = ovalPopoverToolbar.topAnchor.constraint(equalTo: ovalPopoverParent.topAnchor)
    let trailing = ovalPopoverToolbar.trailingAnchor.constraint(equalTo: ovalPopoverParent.trailingAnchor)
    let bottom = ovalPopoverToolbar.bottomAnchor.constraint(equalTo: ovalPopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = ovalPopoverToolbar.arrangedSubviews[ovalPopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
    
    CurrentTool.shapeType = .ellipse
  }

  @IBAction func triangleButtonTapped(_ sender: UIButton) {
    print("Triangle button tapped")
    clearSecondaryPopovers(except: [trianglePopoverParent])

    if trianglePopoverParent.isDescendant(of: self.view) {
      return
    }

    trianglePopoverParent.backgroundColor = UIColor(red: 48/255, green: 52/255, blue: 52/255, alpha: 1)
    self.view.addSubview(trianglePopoverParent)
    trianglePopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = trianglePopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = trianglePopoverParent.topAnchor.constraint(equalTo: triangleButton.topAnchor, constant: 0)
    let widthConstraint = trianglePopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = trianglePopoverParent.heightAnchor.constraint(equalTo: triangleButton.heightAnchor, multiplier: 2)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    trianglePopoverToolbar.axis = .vertical
    trianglePopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trianglePopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    trianglePopoverToolbar.addGestureRecognizer(tapGesture)

    let triangleFilledImage = UIImage(named: "TriangleFilled.pdf")
    let triangleFilledButton = DrawToolbarPersistedButton(image: triangleFilledImage!)
    triangleFilledButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    triangleFilledButton.addTarget(self, action: #selector(triangleFilledTapped(sender:)), for: .touchUpInside)
    triangleFilledButton.tintColor = .white
    
    let triangleImage = UIImage(named: "Triangle.pdf")
    let triangleButton = DrawToolbarPersistedButton(image: triangleImage!)
    triangleButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    triangleButton.addTarget(self, action: #selector(triangleEmptyTapped(sender:)), for: .touchUpInside)
    triangleButton.tintColor = .white

    trianglePopoverToolbar.addArrangedSubview(triangleFilledButton)
    trianglePopoverToolbar.addArrangedSubview(triangleButton)
    trianglePopoverParent.addSubview(trianglePopoverToolbar)
    trianglePopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = trianglePopoverToolbar.leadingAnchor.constraint(equalTo: trianglePopoverParent.leadingAnchor)
    let top = trianglePopoverToolbar.topAnchor.constraint(equalTo: trianglePopoverParent.topAnchor)
    let trailing = trianglePopoverToolbar.trailingAnchor.constraint(equalTo: trianglePopoverParent.trailingAnchor)
    let bottom = trianglePopoverToolbar.bottomAnchor.constraint(equalTo: drawToolbar.bottomAnchor)
    NSLayoutConstraint.activate([leading, trailing, top, bottom])

    if let selectedButton = trianglePopoverToolbar.arrangedSubviews[trianglePopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
    CurrentTool.shapeType = .triangle
  }

  // MARK: - SECONDARY TOOLBAR TAP HANDLDERS
  
  @objc func scribbleLightTapped(sender: UIButton) {
    print("Scribble light tapped")
    scribblePopoverToolbar.savedSelection = 0
    scribbleButton.setImage(UIImage(named: "line_thin.pdf"), for: .normal)
    CurrentTool.setWidth(width: Constants.DRAW_PEN_WIDTH_THIN)
    clearSecondaryPopovers(except: nil)
  }

  @objc func scribbleMediumTapped(sender: UIButton) {
    print("Scribble medium tapped")
    scribblePopoverToolbar.savedSelection = 1
    scribbleButton.setImage(UIImage(named: "line_med.pdf"), for: .normal)
    CurrentTool.setWidth(width: Constants.DRAW_PEN_WIDTH_MEDIUM)
    clearSecondaryPopovers(except: nil)
  }

  @objc func scribbleHeavyTapped(sender: UIButton) {
    print("Scribble heavy tapped")
    scribblePopoverToolbar.savedSelection = 2
    scribbleButton.setImage(UIImage(named: "line_fat.pdf"), for: .normal)
    CurrentTool.setWidth(width: Constants.DRAW_PEN_WIDTH_WIDE)
    clearSecondaryPopovers(except: nil)
  }

  // MARK: - UTIL

  private func clearSecondaryPopovers(except: [UIView]?) {
    for view in popoverParents {
      if except != nil {
        if except!.contains(view) {
          continue
        }
      }
      view.removeFromSuperview()
      view.subviews.forEach { subview in
        if let subStackView = subview as? UIStackView {
          subStackView.safelyRemoveArrangedSubviews()
        }
        subview.removeFromSuperview()
      }
    }
  }



}
