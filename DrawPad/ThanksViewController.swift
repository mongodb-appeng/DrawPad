//
//  ThanksViewController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit

class ThanksViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
  }
    @IBAction func restartPressed(_ sender: Any) {
        print("restartPressed")
        let vc = self.navigationController!.viewControllers[1]
        self.navigationController!.popToViewController(vc, animated: true)
    }
}
