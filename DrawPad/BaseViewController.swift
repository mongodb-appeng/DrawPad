//
//  BaseViewController.swift
//  DrawPad
//
//  Created by Adam Johns on 11/21/19.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit

// There's no good global way to change the status bar color in iOS 13,
// so resorting to a view controller based approach
class BaseViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    let statusBar = UIView(frame: keyWindow!.windowScene!.statusBarManager!.statusBarFrame)
    statusBar.backgroundColor = .black
    keyWindow?.addSubview(statusBar)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

}
