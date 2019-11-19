//
//  CurrentTool.swift
//  DrawPad
//
//  Created by Andrew Morgan on 19/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit

class CurrentTool {
  static var brushWidth: CGFloat = CGFloat(Constants.DRAW_PEN_WIDTH_MEDIUM)
  // TODO add other brush attributes
  
  static func reset() {
    brushWidth = CGFloat(Constants.DRAW_PEN_WIDTH_MEDIUM)
  }
}
