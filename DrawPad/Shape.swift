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
  @objc dynamic var x: CGFloat = 0.0
  /// The y coordinate of the point
  @objc dynamic var y: CGFloat = 0.0
  @objc dynamic var nextPoint: LinkedPoint?

  convenience init(_ point: CGPoint) {
    self.init()
    self.x = point.x
    self.y = point.y
  }

  /// Convert LinkedPoint to native CGPoint type.
  /// - returns: A CGPoint of the same x, y coordinates
  func asCGPoint() -> CGPoint {
    return CGPoint(x: x, y: y)
  }

  /// Convert LinkedPoint as a linked list to a CGRect.
  func asCGRect() -> CGRect {
    guard let pointA = nextPoint else {
      fatalError("Trying to convert a a non-rect linked point to a rect")
    }

    return CGRect(x: pointA.x,
                  y: pointA.y,
                  width: self.x - pointA.x,
                  height: self.y - pointA.y)
  }

  static func ==(_ lhs: LinkedPoint, _ rhs: LinkedPoint) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
  }
}

/// ShapeType enumerates types of possible shapes
@objc enum ShapeType: Int {
  case line, rect, ellipse, triangle
}

/// Shape is the all encompassing class for the various
/// shape types
class Shape: Object {
  /// the deviceId that the shape was instantiated in
  @objc dynamic var deviceId: String = thisDevice!

  /// the last point in the point list
  @objc dynamic var lastPoint: LinkedPoint?

  /// the width of the brush the shape was painted with
  @objc dynamic var brushWidth: CGFloat = 10.0
  /// the opacity the shape was painted with
  @objc dynamic var opacity: CGFloat = 1.0
  /// the color the shape was painted with
  @objc dynamic var color: String = "666666"
  /// whether or not this shape has been erased/undone
  /// NOTE: using the "eraser" feature is semantically
  /// different than whether or not it has been
  /// entirely undone
  @objc dynamic var isErased = false
  /// the type of shape this is
  @objc dynamic var shapeType: ShapeType = .line

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

  private func drawLine(_ context: CGContext, shouldErase: Bool) {
    var nextPoint = lastPoint
    while nextPoint != nil {
      context.move(to: nextPoint!.asCGPoint())
      context.addLine(to: nextPoint!.nextPoint?.asCGPoint() ?? nextPoint!.asCGPoint())
      context.setLineCap(.round)
      context.setBlendMode(.normal)
      context.setLineWidth(brushWidth + (shouldErase ? 2 : 0))
      context.setStrokeColor(shouldErase ? UIColor.white.cgColor : UIColor(hex: color)!.cgColor)
      context.strokePath()
      nextPoint = nextPoint!.nextPoint
    }
  }

  private func drawRect(_ context: CGContext, shouldErase: Bool) {
    context.move(to: lastPoint!.asCGPoint())

    context.addRect(lastPoint!.asCGRect())
    context.setLineCap(.round)
    context.setBlendMode(.normal)
    context.setLineWidth(brushWidth + (shouldErase ? 2 : 0))
    context.setStrokeColor(shouldErase ? UIColor.white.cgColor : UIColor(hex: color)!.cgColor)
    context.strokePath()
  }

  private func drawEllipse(_ context: CGContext, shouldErase: Bool) {
    context.move(to: lastPoint!.asCGPoint())

    context.addEllipse(in: lastPoint!.asCGRect())
    context.setLineCap(.round)
    context.setBlendMode(.normal)
    context.setLineWidth(brushWidth + (shouldErase ? 2 : 0))
    context.setStrokeColor(shouldErase ? UIColor.white.cgColor : UIColor(hex: color)!.cgColor)
    context.strokePath()
  }

  private func drawTriangle(_ context: CGContext, shouldErase: Bool) {
    context.move(to: lastPoint!.asCGPoint())

    context.addLines(between: [
      lastPoint!.asCGPoint(),
      lastPoint!.nextPoint!.asCGPoint(),
      lastPoint!.nextPoint!.nextPoint!.asCGPoint(),
      lastPoint!.asCGPoint()
    ])

    context.setLineCap(.round)
    context.setBlendMode(.normal)
    context.setLineWidth(brushWidth + (shouldErase ? 2 : 0))
    context.setStrokeColor(shouldErase ? UIColor.white.cgColor : UIColor(hex: color)!.cgColor)
    context.strokePath()
  }

  /// Draw the shape with the given context.
  /// - parameter context: the current CGContext
  func draw(_ context: CGContext) {
    guard !isErased else {
      return
    }

    switch shapeType {
    case .line:
      drawLine(context, shouldErase: false)
    case .rect:
      if (lastPoint!.nextPoint != nil) { drawRect(context, shouldErase: false) }
    case .ellipse:
      if (lastPoint!.nextPoint != nil) { drawEllipse(context, shouldErase: false) }
    case .triangle:
      if (lastPoint!.nextPoint != nil) { drawTriangle(context, shouldErase: false) }
    }
  }

  /// Erase the shape with the given context.
  /// Erasing SHOULD effectively paint over the shape
  /// with white "paint". This is to maintain historical state.
  /// - parameter context: the current CGContext
  func erase(_ context: CGContext) {
    switch shapeType {
    case .line:
      drawLine(context, shouldErase: true)
    case .rect:
      if (lastPoint!.nextPoint != nil) { drawRect(context, shouldErase: true) }
    case .ellipse:
      if (lastPoint!.nextPoint != nil) { drawEllipse(context, shouldErase: true) }
    case .triangle:
      if (lastPoint!.nextPoint != nil) { drawTriangle(context, shouldErase: true) }
    }
  }
}
