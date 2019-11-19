//
//  LineThicknessController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit

class LineThicknessController: UIViewController {
    @IBOutlet weak var thinWidthButton: UIButton!
    @IBOutlet weak var mediumWidthButton: UIButton!
    @IBOutlet weak var wideWidthButton: UIButton!
    
    func setWidth (width: Float) {
      CurrentTool.brushWidth = CGFloat(width)
      CurrentTool.shapeType = .line
      self.dismiss(animated: true)
    }
    
    @IBAction func thinWidthButtonPressed(_ sender: Any) {
        setWidth(width: Constants.DRAW_PEN_WIDTH_THIN)
    }
    
    @IBAction func nediumWidthButtonPressed(_ sender: Any) {
      setWidth(width: Constants.DRAW_PEN_WIDTH_MEDIUM)
    }
    
    @IBAction func wideWidthButtonPressed(_ sender: Any) {
      setWidth(width: Constants.DRAW_PEN_WIDTH_WIDE)
    }
}
