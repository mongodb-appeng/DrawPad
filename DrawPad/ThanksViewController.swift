//
//  ThanksViewController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import UIKit

class ThanksViewController: UIViewController {

  @IBOutlet weak var textView: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpTextView()
  }

  private func setUpTextView() {
    let text = self.textView.text as NSString
    let attributedText = NSMutableAttributedString.init(string: text as String)
    let range = (text as NSString).range(of: "mongodb.com/realm")
    let linkColor = UIColor(red: 36/255, green: 123/255, blue: 192/255, alpha: 1)
    attributedText.addAttribute(NSMutableAttributedString.Key.foregroundColor, value: linkColor, range: range)
    self.textView.attributedText = attributedText
    self.textView.textAlignment = .center
    self.textView.font = UIFont(name: self.textView.font!.fontName, size: 16)
  }

  @IBAction func restartPressed(_ sender: Any) {
    print("restartPressed")
    let vc = self.navigationController!.viewControllers[1]
    self.navigationController!.popToViewController(vc, animated: true)
  }

}
