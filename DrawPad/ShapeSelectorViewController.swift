//
//  ShapeSelectorViewController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 19/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import SwiftUI

class ShapeSelectorViewController: UIViewController {
    @IBOutlet weak var square: UIButton!
    @IBOutlet weak var elipse: UIButton!
    @IBOutlet weak var triangle: UIButton!
    
    @IBAction func squarePressed(_ sender: Any) {
        setShape(shapeType: .rect)
    }
    
    @IBAction func elipsePressed(_ sender: Any) {
        setShape(shapeType: .ellipse)
    }
    @IBAction func trianglePressed(_ sender: Any) {
        setShape(shapeType: .triangle)
    }
    
    func setShape (shapeType: ShapeType) {
    CurrentTool.shapeType = shapeType
    self.dismiss(animated: true)
  }

}
