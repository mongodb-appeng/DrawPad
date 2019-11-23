//
//  CurrentTool.swift
//  DrawPad
//
//  Created by Andrew Morgan on 19/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit

class CurrentTool {
  static var brushWidth: CGFloat = CGFloat(Constants.DRAW_PEN_WIDTH_THIN)
  static var shapeType: ShapeType = .line
  static var color = UIColor.black
  static var fontStyle: FontStyle = .normal
  static var stampFile: String = ""
  
  static func setWidth (width: Float) {
    CurrentTool.brushWidth = CGFloat(width)
    CurrentTool.shapeType = .line
  }
  
  static func reset() {
    brushWidth = CGFloat(Constants.DRAW_PEN_WIDTH_MEDIUM)
    shapeType = .line
    color = UIColor.black
    fontStyle = .normal
    stampFile = ""
  }
}
