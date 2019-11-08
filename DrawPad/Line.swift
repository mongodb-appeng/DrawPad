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

class LinkedPoint: Object {
  @objc dynamic var x: CGFloat = 0.0
  @objc dynamic var y: CGFloat = 0.0
  @objc dynamic var nextPoint: LinkedPoint?

  convenience init(_ point: CGPoint) {
    self.init()
    self.x = point.x
    self.y = point.y
  }
  
  func asCGPoint() -> CGPoint {
    return CGPoint(x: x, y: y)
  }

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

@objc enum ShapeType: Int {
  case line, rect, ellipse, triangle
}

class Shape: Object {
  @objc dynamic var deviceId: String = thisDevice!

  @objc dynamic var lastPoint: LinkedPoint?

  @objc dynamic var brushWidth: CGFloat = 10.0
  @objc dynamic var opacity: CGFloat = 1.0
  @objc dynamic var color: String = "666666"
  @objc dynamic var isErased = false
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

  func draw(_ context: CGContext) {
    guard !isErased else {
      return
    }

    switch shapeType {
    case .line:
      drawLine(context, shouldErase: false)
    case .rect:
      drawRect(context, shouldErase: false)
    case .ellipse:
      drawEllipse(context, shouldErase: false)
    case .triangle:
      drawTriangle(context, shouldErase: false)
    }
  }

  func erase(_ context: CGContext) {
    switch shapeType {
    case .line:
      drawLine(context, shouldErase: true)
    case .rect:
      drawRect(context, shouldErase: true)
    case .ellipse:
      drawEllipse(context, shouldErase: true)
    case .triangle:
      drawTriangle(context, shouldErase: true)
    }
  }
}

class Drawing: Object {
  let shapes = List<Shape>()

  func undoLast(_ context: CGContext, realm: Realm) {
    guard let shape = shapes.last(where: { $0.deviceId == thisDevice && !$0.isErased }) else {
      return
    }

    shape.erase(context)

    try! realm.write { shape.isErased = true }

    shapes.forEach { $0.draw(context) }
  }
}
