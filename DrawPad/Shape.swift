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

import RealmSwift
import UIKit

let thisDevice = UIDevice.current.identifierForVendor?.uuidString

/// A singly linked list of points
class LinkedPoint: Object {
  /// The x coordinate of the point
  @objc dynamic var x: Float = 0.0
  /// The y coordinate of the point
  @objc dynamic var y: Float = 0.0
  @objc dynamic var nextPoint: LinkedPoint?
  var X: CGFloat {
    get {
      return CGFloat(x)
    }
    set (X) {
      x = Float(X)
    }
  }
  var Y: CGFloat {
    get {
      return CGFloat(y)
    }
    set (Y) {
      y = Float(Y)
    }
  }
  convenience init(_ point: CGPoint) {
    self.init()
    self.X = point.x
    self.Y = point.y
  }

  /// Convert LinkedPoint to native CGPoint type.
  /// - returns: A CGPoint of the same x, y coordinates
  func asCGPoint() -> CGPoint {
    return CGPoint(x: X, y: Y)
  }

  /// Convert LinkedPoint as a linked list to a CGRect.
  func asCGRect() -> CGRect {
    guard let pointA = nextPoint else {
      fatalError("Trying to convert a a non-rect linked point to a rect")
    }

    return CGRect(x: pointA.X,
                  y: pointA.Y,
                  width: self.X - pointA.X,
                  height: self.Y - pointA.Y)
  }
  
  func rectHeight() -> Int {
    guard let pointA = nextPoint else {
        fatalError("Trying to convert a a non-rect linked point to a rect")
    }
    
    return abs(Int(y - pointA.y))
  }

  static func ==(_ lhs: LinkedPoint, _ rhs: LinkedPoint) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
  }
}

/// ShapeType enumerates types of possible shapes
@objc enum ShapeType: Int {
  case line, rect, ellipse, triangle, stamp, text
}

/// Shape is the all encompassing class for the various
/// shape types
class Shape: Object {
  @objc dynamic var _id: String = UUID().uuidString

  /// the deviceId that the shape was instantiated in
  @objc dynamic var deviceId: String = thisDevice!

  /// the last point in the point list
  @objc dynamic var lastPoint: LinkedPoint?

  /// the width of the brush the shape was painted with
  @objc dynamic var brushWidthFloat: Float = 10.0
  
  var brushWidth: CGFloat {
    get {
      return CGFloat(brushWidthFloat)
    }
    set (width) {
      brushWidthFloat = Float(width)
    }
  }
  
  /// the color the shape was painted with
  @objc dynamic var color: String = "666666"
  
  @objc dynamic var image: String = ""
  @objc dynamic var text: String = "Your text goes here"
  
  /// the type of shape this is
  @objc dynamic var shapeType: ShapeType = .line

  override static func primaryKey() -> String? {
      return "_id"
  }
  
  func append(point: LinkedPoint) {
    point.nextPoint = self.lastPoint
    self.lastPoint = point
  }

  func replaceHead(point: LinkedPoint) {
    if let nextPoint = self.lastPoint?.nextPoint {
      point.nextPoint = nextPoint
    } else if let nextPoint = self.lastPoint {
      point.nextPoint = nextPoint
    }

    self.lastPoint = point
  }

  private func drawLine(_ context: CGContext) {
    var nextPoint = lastPoint
    while nextPoint != nil {
      context.move(to: nextPoint!.asCGPoint())
      context.addLine(to: nextPoint!.nextPoint?.asCGPoint() ?? nextPoint!.asCGPoint())
      context.setLineCap(.round)
      context.setBlendMode(.normal)
      context.setLineWidth(brushWidth)
      context.setStrokeColor(UIColor(hex: color)!.cgColor)
      context.strokePath()
      nextPoint = nextPoint!.nextPoint
    }
  }

  private func drawRect(_ context: CGContext) {
    context.move(to: lastPoint!.asCGPoint())
    
    let rectangle = lastPoint!.asCGRect()
    context.addRect(rectangle)
    context.setLineCap(.round)
    context.setBlendMode(.normal)
    context.setLineWidth(brushWidth)
    context.setStrokeColor(UIColor(hex: color)!.cgColor)
    context.setFillColor(UIColor(hex: color)!.cgColor)
    UIRectFill (rectangle)
    context.strokePath()
  }

  private func drawEllipse(_ context: CGContext) {
    context.move(to: lastPoint!.asCGPoint())
    let rectangle = lastPoint!.asCGRect()
    context.setLineCap(.round)
    context.setBlendMode(.normal)
    context.setLineWidth(brushWidth)
    context.setStrokeColor(UIColor(hex: color)!.cgColor)
    context.setFillColor(UIColor(hex: color)!.cgColor)
    context.fillEllipse(in: rectangle)
    context.strokePath()
  }

  private func drawTriangle(_ context: CGContext) {
    context.move(to: lastPoint!.asCGPoint())

    context.addLines(between: [
      lastPoint!.asCGPoint(),
      lastPoint!.nextPoint!.asCGPoint(),
      lastPoint!.nextPoint!.nextPoint!.asCGPoint(),
      lastPoint!.asCGPoint()
    ])

    context.setLineCap(.round)
    context.setBlendMode(.normal)
    context.setLineWidth(brushWidth)
    context.setStrokeColor(UIColor(hex: color)!.cgColor)
    context.setFillColor(UIColor(hex: color)!.cgColor)
    context.fillPath()
  }

  private func drawStamp(_ context: CGContext) {
    context.move(to: lastPoint!.asCGPoint())
    let image = UIImage(named: "grumpy_cat_stamp.png")!
    image.draw(in: lastPoint!.asCGRect(), blendMode: .normal, alpha: 1.0)
  }
  
  private func drawText(_ context: CGContext) {
    context.move(to: lastPoint!.asCGPoint())
    let height = lastPoint!.rectHeight()
    let fontSize = abs(height/4)
    let font = UIFont.systemFont(ofSize: CGFloat(fontSize))
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .left
    guard let myColor = UIColor(hex: color) else {
      print ("Could not calc color")
      return
    }
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: myColor,
        .paragraphStyle: paragraphStyle
    ]

    let attributedString = NSAttributedString(string: text, attributes: attributes)
    attributedString.draw(in: lastPoint!.asCGRect())
}

  /// Draw the shape with the given context.
  /// - parameter context: the current CGContext
  func draw(_ context: CGContext) {
    switch shapeType {
    case .line:
      drawLine(context)
    case .rect:
      if (lastPoint!.nextPoint != nil) { drawRect(context) }
    case .ellipse:
      if (lastPoint!.nextPoint != nil) { drawEllipse(context) }
    case .triangle:
      if (lastPoint!.nextPoint != nil) { drawTriangle(context) }
    case .stamp:
      if (lastPoint!.nextPoint != nil) { drawStamp(context) }
    case .text:
      if (lastPoint!.nextPoint != nil) { drawText(context) }
    }
  }
}
