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

class DrawViewController: BaseViewController, UITextFieldDelegate {

  // MARK: - OUTLETS
  
  @IBOutlet weak var mainImageView: UIImageView!
  @IBOutlet weak var tempImageView: UIImageView!
  @IBOutlet weak var hiddenTextField: UITextField!
  
  @IBOutlet weak var leftToolbarParent: UIView!
  @IBOutlet weak var drawToolbar: DrawToolbarStackView!
  @IBOutlet weak var parentGridHorizontalStackView: UIStackView!
  @IBOutlet weak var scribbleButton: DrawToolbarPopoverButton!
  @IBOutlet weak var sansSerifButton: DrawToolbarPopoverButton!
  @IBOutlet weak var opacityButton: DrawToolbarPopoverButton!

  // MARK: - INIT
  
  let scribblePopoverParent = UIView()
  let scribblePopoverToolbar = DrawToolbarStackView()
  let sansSerifPopoverParent = UIView()
  let sansSerifPopoverToolbar = DrawToolbarStackView()
  let stampsPopoverParent = UIView()
  let stampsPopoverToolbar = DrawToolbarStackView()
  let opacityPopoverParent = UIView()
  let opacityPopoverToolbar = DrawToolbarStackView()
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
    popoverParents = [scribblePopoverParent, sansSerifPopoverParent, stampsPopoverParent, opacityPopoverParent]
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
    guard let image = mainImageView.image!.jpegData(compressionQuality: 1) else {
      print("Failed to get to the image")
      return nil
    }
    return image
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
   
    currentShape = Shape()
    currentShape!.shapeType = CurrentTool.shapeType
    currentShape!.color = CurrentTool.color.toHex
    currentShape!.brushWidth = CurrentTool.brushWidth

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
    
    switch CurrentTool.shapeType {
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

  @IBAction func toolbarButtonTapped(_ sender: UIButton) {
    print("Main toolbar button tapped")
    if let button = sender as? DrawToolbarPersistedButton {
      self.drawToolbar.clearCurrentButtonSelection()
      button.select()
    }
  }
  // TODO - Implement fonts
  @objc func scribblePopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary scribble toolbar tap")
    scribblePopoverToolbar.clearCurrentButtonSelection()
  }

  @objc func sansSerifPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary sans serif toolbar tap")
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
  }

  // TODO - Add stamps
  @objc func stampsPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary stamps toolbar tap")
    stampsPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.shapeType = .stamp
  }
  
  // TODO - Add shades of grey
  
  @objc func opacityPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
  }
  
  @objc func opacityBlackTapped(sender: UIButton) {
    print("Secondary Black opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
    guard let pencil = Pencil(tag: 1) else {
      return
    }
    CurrentTool.color = pencil.color
  }

  @objc func opacityDarkestTapped(sender: UIButton) {
    print("Secondary Darkest Grey opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
    guard let pencil = Pencil(tag: 2) else {
      return
    }
    CurrentTool.color = pencil.color
  }

  @objc func opacityMidTapped(sender: UIButton) {
    print("Secondary Mid Grey opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
    guard let pencil = Pencil(tag: 3) else {
      return
    }
    CurrentTool.color = pencil.color
  }
  
  @objc func opacityLightestTapped(sender: UIButton) {
    print("Secondary Lightest Grey opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
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
  }

  @IBAction func scribbleButtonTapped(_ sender: UIButton) {
    print("Scribble button tapped")

    clearSecondaryPopovers(except: [scribblePopoverParent])
    if scribblePopoverParent.isDescendant(of: self.view) {
      return
    }

    scribblePopoverParent.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 26/255, alpha: 1)
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

    // TODO: UPDATE IMAGES TO SHOW DIFFERENT WIDTHS

    let scribbleLightImage = UIImage(systemName: "scribble")
    let scribbleLightButton = DrawToolbarPersistedButton(image: scribbleLightImage!)
    scribbleLightButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.addTarget(self, action: #selector(scribbleLightTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.tintColor = .white

    let scribbleMediumImage = UIImage(systemName: "scribble")
    let scribbleMediumButton = DrawToolbarPersistedButton(image: scribbleMediumImage!)
    scribbleMediumButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleMediumButton.addTarget(self, action: #selector(scribbleMediumTapped(sender:)), for: .touchUpInside)
    scribbleMediumButton.tintColor = .white

    let scribbleHeavyImage = UIImage(systemName: "scribble")
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
    sansSerifPopoverParent.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 26/255, alpha: 1)
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

    // TODO: UPDATE IMAGES TO SHOW DIFFERENT WIDTHS

    let sansSerifNormalImage = UIImage(systemName: "textbox")
    let sansSerifNormalButton = DrawToolbarPersistedButton(image: sansSerifNormalImage!)
    sansSerifNormalButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    sansSerifNormalButton.addTarget(self, action: #selector(sansSerifNormalTapped(sender:)), for: .touchUpInside)
    sansSerifNormalButton.tintColor = .white

    let sansSerifSerifImage = UIImage(systemName: "textbox")
    let sansSerifSerifButton = DrawToolbarPersistedButton(image: sansSerifSerifImage!)
    sansSerifSerifButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    sansSerifSerifButton.addTarget(self, action: #selector(sansSerifSerifTapped(sender:)), for: .touchUpInside)
    sansSerifSerifButton.tintColor = .white

    let sansSerifMonoImage = UIImage(systemName: "textbox")
    let sansSerifMonoButton = DrawToolbarPersistedButton(image: sansSerifMonoImage!)
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
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.fontStyle = .normal
    sansSerifButton.setTitle("Sans Serif", for: .normal)
  }

  @objc func sansSerifSerifTapped(sender: UIButton) {
    print("Secondary Text serif toolbar tap")
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.fontStyle = .serif
    sansSerifButton.setTitle("Serif", for: .normal)
  }
  
  @objc func sansSerifMonoTapped(sender: UIButton) {
    print("Secondary Text mono toolbar tap")
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
    CurrentTool.fontStyle = .monospace
    sansSerifButton.setTitle("Monospace", for: .normal)
  }
  
  @IBAction func stampsButtonTapped(_ sender: UIButton) {
    print("Stamps button tapped")
    clearSecondaryPopovers(except: [stampsPopoverParent])

    if stampsPopoverParent.isDescendant(of: self.view) {
      return
    }

    stampsPopoverParent.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 26/255, alpha: 1)
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

    let scribbleLightImage = UIImage(systemName: "scribble")
    let scribbleLightButton = DrawToolbarPersistedButton(image: scribbleLightImage!)
    scribbleLightButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.tintColor = .white

    let textboxImage = UIImage(systemName: "scribble")
    let textBoxButton = DrawToolbarPersistedButton(image: textboxImage!)
    textBoxButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton.tintColor = .white

    let squareImage = UIImage(systemName: "scribble")
    let squareButton = DrawToolbarPersistedButton(image: squareImage!)
    squareButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton.tintColor = .white

    let scribbleLightImage2 = UIImage(systemName: "scribble")
    let scribbleLightButton2 = DrawToolbarPersistedButton(image: scribbleLightImage2!)
    scribbleLightButton2.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton2.tintColor = .white

    let textboxImage2 = UIImage(systemName: "scribble")
    let textBoxButton2 = DrawToolbarPersistedButton(image: textboxImage2!)
    textBoxButton2.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton2.tintColor = .white

    let squareImage2 = UIImage(systemName: "scribble")
    let squareButton2 = DrawToolbarPersistedButton(image: squareImage2!)
    squareButton2.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton2.tintColor = .white

    let scribbleLightImage3 = UIImage(systemName: "scribble")
    let scribbleLightButton3 = DrawToolbarPersistedButton(image: scribbleLightImage3!)
    scribbleLightButton3.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton3.tintColor = .white

    let textboxImage3 = UIImage(systemName: "scribble")
    let textBoxButton3 = DrawToolbarPersistedButton(image: textboxImage3!)
    textBoxButton3.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton3.tintColor = .white

    let squareImage3 = UIImage(systemName: "scribble")
    let squareButton3 = DrawToolbarPersistedButton(image: squareImage3!)
    squareButton3.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton3.tintColor = .white

    let scribbleLightImage4 = UIImage(systemName: "scribble")
    let scribbleLightButton4 = DrawToolbarPersistedButton(image: scribbleLightImage4!)
    scribbleLightButton4.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton4.tintColor = .white

    let textboxImage4 = UIImage(systemName: "scribble")
    let textBoxButton4 = DrawToolbarPersistedButton(image: textboxImage4!)
    textBoxButton4.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton4.tintColor = .white

    let squareImage4 = UIImage(systemName: "scribble")
    let squareButton4 = DrawToolbarPersistedButton(image: squareImage4!)
    squareButton4.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton4.tintColor = .white

    let squareImage5 = UIImage(systemName: "scribble")
    let squareButton5 = DrawToolbarPersistedButton(image: squareImage5!)
    squareButton5.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton5.tintColor = .white

    stampsPopoverToolbar.addArrangedSubview(scribbleLightButton)
    stampsPopoverToolbar.addArrangedSubview(textBoxButton)
    stampsPopoverToolbar.addArrangedSubview(squareButton)
    stampsPopoverToolbar.addArrangedSubview(scribbleLightButton2)
    stampsPopoverToolbar.addArrangedSubview(textBoxButton2)
    stampsPopoverToolbar.addArrangedSubview(squareButton2)
    stampsPopoverToolbar.addArrangedSubview(scribbleLightButton3)
    stampsPopoverToolbar.addArrangedSubview(textBoxButton3)
    stampsPopoverToolbar.addArrangedSubview(squareButton3)
    stampsPopoverToolbar.addArrangedSubview(scribbleLightButton4)
    stampsPopoverToolbar.addArrangedSubview(textBoxButton4)
    stampsPopoverToolbar.addArrangedSubview(squareButton4)
    stampsPopoverToolbar.addArrangedSubview(squareButton5)
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

  @IBAction func opacityButtonTapped(_ sender: UIButton) {
    print("Opacity button tapped")
    clearSecondaryPopovers(except: [opacityPopoverParent])

    if opacityPopoverParent.isDescendant(of: self.view) {
      return
    }

    opacityPopoverParent.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 26/255, alpha: 1)
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

    // TODO: UPDATE IMAGES

    let blackShadeImage = UIImage(systemName: "eyedropper")
    let blackShadeButton = DrawToolbarPersistedButton(image: blackShadeImage!)
    blackShadeButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    blackShadeButton.addTarget(self, action: #selector(opacityBlackTapped(sender:)), for: .touchUpInside)
    blackShadeButton.tintColor = .white

    let darkestShadeImage = UIImage(systemName: "eyedropper")
    let darkestShadeButton = DrawToolbarPersistedButton(image: darkestShadeImage!)
    darkestShadeButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    darkestShadeButton.addTarget(self, action: #selector(opacityDarkestTapped(sender:)), for: .touchUpInside)
    darkestShadeButton.tintColor = .white

    let midShadeImage = UIImage(systemName: "eyedropper")
    let midShadeButton = DrawToolbarPersistedButton(image: midShadeImage!)
    midShadeButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    midShadeButton.addTarget(self, action: #selector(opacityMidTapped(sender:)), for: .touchUpInside)
    midShadeButton.tintColor = .white

    let lightestShadeImage = UIImage(systemName: "eyedropper")
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
    clearSecondaryPopovers(except: nil)
    CurrentTool.shapeType = .rect
  }

  @IBAction func circleButtonTapped(_ sender: UIButton) {
    print("Circle button tapped")
    clearSecondaryPopovers(except: nil)
    CurrentTool.shapeType = .ellipse
  }

  @IBAction func triangleButtonTapped(_ sender: UIButton) {
    print("Triangle button tapped")
    clearSecondaryPopovers(except: nil)
    CurrentTool.shapeType = .triangle
  }

  // MARK: - SECONDARY TOOLBAR TAP HANDLDERS

  @objc func scribbleLightTapped(sender: UIButton) {
    print("Scribble light tapped")
    scribblePopoverToolbar.savedSelection = 0
    CurrentTool.setWidth(width: Constants.DRAW_PEN_WIDTH_THIN)
    clearSecondaryPopovers(except: nil)
  }

  @objc func scribbleMediumTapped(sender: UIButton) {
    print("Scribble medium tapped")
    scribblePopoverToolbar.savedSelection = 1
    CurrentTool.setWidth(width: Constants.DRAW_PEN_WIDTH_MEDIUM)
    clearSecondaryPopovers(except: nil)
  }

  @objc func scribbleHeavyTapped(sender: UIButton) {
    print("Scribble heavy tapped")
    scribblePopoverToolbar.savedSelection = 2
    CurrentTool.setWidth(width: Constants.DRAW_PEN_WIDTH_WIDE)
    clearSecondaryPopovers(except: nil)
  }

  // TODO: ADD THE REST OF THE TAP HANDLERS THE SAME WAY THESE WERE ADDED

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
