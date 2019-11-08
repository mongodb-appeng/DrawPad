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

class ViewController: UIViewController {
  @IBOutlet weak var mainImageView: UIImageView!
  @IBOutlet weak var tempImageView: UIImageView!
  
  let realm: Realm
  let strokes: Results<Stroke> // `Results` is a Realm class, use like `List`
  let storedImages: Results<StoredImage>
  var notificationToken: NotificationToken? // Let's us know when something has changed in the Realm
  var strokeStartingPoint = 0
  
  var lastPoint = CGPoint.zero
  var color = UIColor.black
  var brushWidth: CGFloat = 10.0
  var opacity: CGFloat = 1.0
  var swiped = false
  private var lineCount = 0
  
//  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//      print("init1 called")
//      let config = SyncUser.current?.configuration(realmURL: Constants.REALM_URL, fullSynchronization: true)
//      self.realm = try! Realm(configuration: config!)
//      self.strokes = realm.objects(Stroke.self).sorted(byKeyPath: "timestamp", ascending: false)
//      super.init(nibName: nil, bundle: nil)
//  }
  
  required init?(coder aDecoder: NSCoder) {
    let config = SyncUser.current?.configuration(realmURL: Constants.REALM_URL, fullSynchronization: true)
    self.realm = try! Realm(configuration: config!)
    self.strokes = realm.objects(Stroke.self).sorted(byKeyPath: "timestamp", ascending: true)
    self.storedImages = realm.objects(StoredImage.self).sorted(byKeyPath: "timestamp", ascending: true)
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    notificationToken = strokes.observe { [weak self] (changes) in
        switch changes {
        case .initial:
            // Results are now populated and can be accessed without blocking the UI
            print("Can refresh the data here if needed")
        case .update(_, let deletions, let insertions, _):
          for _ in insertions {
            print("Single insert; \(self!.strokes.count)")
            self!.processChanges()
//            self!.processLastChange()
          }
          for _ in deletions {
            print("Single delete; \(self!.strokes.count)")
            if self!.strokes.count == 0 {
              self!.mainImageView.image = nil
              self!.tempImageView.image = nil
            }
          }
        case .error(let error):
            // An error occurred while opening the Realm file on the background worker thread
            fatalError("\(error)")
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
    try! realm.write {
      realm.delete(realm.objects(Point.self))
      for stroke in strokes {
        realm.delete(stroke)
      }
    }
    strokeStartingPoint = 0
  }
  
  @IBAction func sharePressed(_ sender: Any) {
    guard let image = extractPNG() else {
      print("Failed to extract image")
      return
    }
    let storedImage = StoredImage(image: image, name: "andrewjamesmorgan@gmail.com")
    try! self.realm.write {
      self.realm.add(storedImage)
      print("storedImage.email \(storedImage.email)")
    }

    let imageURL = AWS.uploadImage(image: image, email: "andrewjamesmorgan@gmail.com")
    print("url: \(imageURL)")
    if imageURL != "" {
      try! self.realm.write {
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
      opacity = 1.0
    }
  }
  
//  func processLastChange () {
//
//    let stroke = strokes[0]
//    if stroke.device != thisDevice {
//      // This stroke is from another device and so we need to render it on this one.
//      let startPoint = CGPoint(x: stroke.fromPoint!.x, y: stroke.fromPoint!.y)
//      let endPoint = CGPoint(x: stroke.toPoint!.x, y: stroke.toPoint!.y)
//      let color = UIColor(hex: stroke.color)
//
//      drawLine(from: startPoint, to: endPoint, remote: true, width: stroke.brushWidth, color: color!, opacity: stroke.opacity)
//    }
//  }
  
  func processChanges () {
    let start = strokeStartingPoint
    if start >= strokes.count {
      print("Nothing to do")
      return
    }
    for index in start ..< strokes.count {
      strokeStartingPoint = index
      let stroke = strokes[index]
      if stroke.device != thisDevice {
        // This stroke is from another device and so we need to render it on this one.
        let startPoint = CGPoint(x: stroke.fromPoint!.x, y: stroke.fromPoint!.y)
        let endPoint = CGPoint(x: stroke.toPoint!.x, y: stroke.toPoint!.y)
        let color = UIColor(hex: stroke.color)
        
        drawLine(from: startPoint, to: endPoint, remote: true, width: stroke.brushWidth, color: color!, opacity: stroke.opacity)
      }
    }
  }
  
  func extractPNG() -> Data? {
    guard let image = mainImageView.image!.pngData() else {
      print("Failed to get to the image")
      return nil
    }
    return image
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
  
  func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint, remote noSync: Bool = false, width: CGFloat, color col: UIColor, opacity op: CGFloat) {
    
    lineCount += 1
    print ("Drawing line number \(lineCount)")
    if !noSync {
      print("Creating a new stroke")
      let stroke = Stroke()
      let startingPoint = Point(fromPoint.x, fromPoint.y)
      let endPoint = Point(toPoint.x, toPoint.y)
      stroke.fromPoint = startingPoint
      stroke.toPoint = endPoint
      stroke.color = col.toHex
      stroke.brushWidth = width
      stroke.opacity = op
      try! self.realm.write {
          self.realm.add(stroke)
      }
    }
    print ("Color: \(col.toHex)")
    UIGraphicsBeginImageContext(view.frame.size)
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }
      tempImageView.image?.draw(in: view.bounds)
      
      context.move(to: fromPoint)
      context.addLine(to: toPoint)
      context.setLineCap(.round)
      context.setBlendMode(.normal)
      context.setLineWidth(width)
      context.setStrokeColor(col.cgColor)
      context.strokePath()
      tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
      tempImageView.alpha = op
    UIGraphicsEndImageContext()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    swiped = false
    lastPoint = touch.location(in: view)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    swiped = true
    let currentPoint = touch.location(in: view)
    drawLine(from: lastPoint, to: currentPoint, remote: false, width: brushWidth, color: color, opacity: opacity)
    
    lastPoint = currentPoint
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if !swiped {
      // draw a single point
      drawLine(from: lastPoint, to: lastPoint, remote: false, width: brushWidth, color: color, opacity: opacity)
    }
    mergeViews()
//    // Merge tempImageView into mainImageView
//    UIGraphicsBeginImageContext(mainImageView.frame.size)
//    mainImageView.image?.draw(in: view.bounds, blendMode: .normal, alpha: 1.0)
//    tempImageView?.image?.draw(in: view.bounds, blendMode: .normal, alpha: opacity)
//    mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
//    UIGraphicsEndImageContext()
//
//    tempImageView.image = nil
  }
}



// MARK: - SettingsViewControllerDelegate

extension ViewController: SettingsViewControllerDelegate {
  func settingsViewControllerFinished(_ settingsViewController: SettingsViewController) {
    brushWidth = settingsViewController.brush
    opacity = settingsViewController.opacity
    color = UIColor(red: settingsViewController.red,
                    green: settingsViewController.green,
                    blue: settingsViewController.blue,
                    alpha: opacity)
    dismiss(animated: true)
  }
}

