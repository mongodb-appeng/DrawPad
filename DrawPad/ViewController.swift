/// Copyright (c) 2018 MongoDB Inc
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

class ViewController: UIViewController, SettingsViewControllerDelegate {
  @IBOutlet weak var mainImageView: UIImageView!
  @IBOutlet weak var tempImageView: UIImageView!
  
  let realm: Realm
  var shapes: Results<Shape>
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
    let config = SyncUser.current?.configuration(realmURL: Constants.REALM_URL,
                                                 fullSynchronization: true)
    self.realm = try! Realm(configuration: config!)
    self.shapes = realm.objects(Shape.self)

    super.init(coder: aDecoder)
  }

  private func draw(_ block: (CGContext) -> Void) {
    UIGraphicsBeginImageContext(self.view.frame.size)
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }
    self.tempImageView.image?.draw(in: self.view.bounds)

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
      switch changes {
      case .initial(let shapes):
        strongSelf.draw { context in
          shapes.forEach { $0.draw(context) }
        }
        break
      case .update(let shapes, _, let insertions, let modifications):
        (insertions + modifications).forEach { index in
          if shapes[index].deviceId != thisDevice {
            strongSelf.draw { context in
              let shape = shapes[index]
              if shape.isErased {
                shape.erase(context)
                shapes.forEach { $0.draw(context) }
              } else {
                shape.draw(context)
              }
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
    print("In ViewController")
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

    draw { context in
      self.shapes.forEach { $0.erase(context) }
    }

    try! realm.write {
      self.shapes.forEach { $0.isErased = true }
    }
  }
  
  @IBAction func sharePressed(_ sender: Any) {
    // TODO crashes app
    guard let image = mainImageView.image else {
      print ("Failed to get image")
      return
    }
    let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
    present(activity, animated: true)
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
  
  func mergeViews() {
    // Merge tempImageView into mainImageView
    UIGraphicsBeginImageContext(mainImageView.frame.size)
    mainImageView.image?.draw(in: view.bounds, blendMode: .normal, alpha: 1.0)
    tempImageView?.image?.draw(in: view.bounds, blendMode: .normal, alpha: opacity)
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
      try! realm.write {
        realm.add(currentShape!)
      }
    }

    swiped = false

    try! realm.write {
      currentShape!.append(point: LinkedPoint(touch.location(in: view)))
    }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }

    let currentPoint = touch.location(in: view)

    draw { context in
      switch shapeType {
        // if the shape is a line, simply append the current point to the head of the list
      case .line:
        try! realm.write {
          currentShape!.append(point: LinkedPoint(currentPoint))
        }
        // if the shape is a rect or an ellipse, replace the head of the list
        // with the dragged point. the LinkedPoint list should always contain
        // (x₁, y₁) and (x₂, y₂), the top left and and bottom right corners
        // of the rect
      case .rect, .ellipse:
        // if 'swiped' (a.k.a. not a single point), erase the current shape,
        // which is effectively acting as a draft. then redraw the current
        // state
        if swiped {
          currentShape!.erase(context)
          self.shapes.forEach { $0.draw(context) }
        }
        try! realm.write {
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
          currentShape!.erase(context)
          self.shapes.forEach { $0.draw(context) }
        }
        try! realm.write {
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

    // if the shape is not a line, it exists in a draft state.
    // add it to the realm now
    // TODO: move the "draft" business logic out of the view
    if shapeType != .line {
      try! realm.write {
        realm.add(currentShape!)
      }
    }
    mergeViews()
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
      guard let shape = shapes.last(where: { $0.deviceId == thisDevice && !$0.isErased }) else {
        return
      }

      shape.erase(context)

      try! realm.write { shape.isErased = true }

      shapes.forEach { $0.draw(context) }
    }

    currentShape = nil
  }

  // MARK: - Shape UI controls

  // TODO: These methods should all be expanded and work together
  // relative to the UI.

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
}
