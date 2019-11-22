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

import UIKit

class DrawViewController: BaseViewController {

  @IBOutlet weak var leftToolbarParent: UIView!
  @IBOutlet weak var drawToolbar: DrawToolbarStackView!
  @IBOutlet weak var parentGridHorizontalStackView: UIStackView!
  @IBOutlet weak var scribbleButton: DrawToolbarPopoverButton!
  @IBOutlet weak var sansSerifButton: DrawToolbarPopoverButton!
  @IBOutlet weak var opacityButton: DrawToolbarPopoverButton!

  let scribblePopoverParent = UIView()
  let scribblePopoverToolbar = DrawToolbarStackView()
  let sansSerifPopoverParent = UIView()
  let sansSerifPopoverToolbar = DrawToolbarStackView()
  let stampsPopoverParent = UIView()
  let stampsPopoverToolbar = DrawToolbarStackView()
  let opacityPopoverParent = UIView()
  let opacityPopoverToolbar = DrawToolbarStackView()
  var popoverParents: [UIView] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    popoverParents = [scribblePopoverParent, sansSerifPopoverParent, stampsPopoverParent, opacityPopoverParent]
  }

  @IBAction func toolbarButtonTapped(_ sender: UIButton) {
    print("Main toolbar button tapped")
    if let button = sender as? DrawToolbarPersistedButton {
      self.drawToolbar.clearCurrentButtonSelection()
      button.select()
    }
  }

  @objc func scribblePopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary scribble toolbar tap")
    scribblePopoverToolbar.clearCurrentButtonSelection()
  }

  @objc func sansSerifPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary sans serif toolbar tap")
    sansSerifPopoverToolbar.clearCurrentButtonSelection()
  }

  @objc func stampsPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary stamps toolbar tap")
    stampsPopoverToolbar.clearCurrentButtonSelection()
  }

  @objc func opacityPopoverTapHandler(gesture: UITapGestureRecognizer) {
    print("Secondary opacity toolbar tap")
    opacityPopoverToolbar.clearCurrentButtonSelection()
  }

  @objc func secondaryToolbarButtonTapped(sender: DrawToolbarPersistedButton) {
    print("Secondary button tap")
    sender.select()
  }

  // MARK: - PRIMARY TOOLBAR TAP HANDLDERS

  @IBAction func finishButtonTapped(_ sender: UIButton) {
    print("Finish button tapped")
  }

  @IBAction func undoButtonTapped(_ sender: UIButton) {
    print("Undo button tapped")
  }

  @IBAction func pencilButtonTapped(_ sender: UIButton) {
    print("Pencil button tapped")
    clearSecondaryPopovers(except: nil)
  }

  @IBAction func scribbleButtonTapped(_ sender: UIButton) {
    print("Scribble button tapped")

    clearSecondaryPopovers(except: [scribblePopoverParent])
    if scribblePopoverParent.isDescendant(of: self.view) {
      return
    }

    scribblePopoverParent.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 26/255, alpha: 1)
    self.view.addSubview(scribblePopoverParent)
    scribblePopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = scribblePopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = scribblePopoverParent.topAnchor.constraint(equalTo: scribbleButton.topAnchor, constant: 0)
    let widthConstraint = scribblePopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = scribblePopoverParent.heightAnchor.constraint(equalTo: scribbleButton.heightAnchor, multiplier: 3)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    scribblePopoverToolbar.axis = .vertical
    scribblePopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(scribblePopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    scribblePopoverToolbar.addGestureRecognizer(tapGesture)

    // TODO: UPDATE IMAGES TO SHOW DIFFERENT WIDTHS

    let scribbleLightImage = UIImage(systemName: "scribble")
    let scribbleLightButton = DrawToolbarPersistedButton(image: scribbleLightImage!)
    scribbleLightButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.addTarget(self, action: #selector(scribbleLightTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.tintColor = .white

    let scribbleMediumImage = UIImage(systemName: "scribble")
    let scribbleMediumButton = DrawToolbarPersistedButton(image: scribbleMediumImage!)
    scribbleMediumButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleMediumButton.addTarget(self, action: #selector(scribbleMediumTapped(sender:)), for: .touchUpInside)
    scribbleMediumButton.tintColor = .white

    let scribbleHeavyImage = UIImage(systemName: "scribble")
    let scribbleHeavyButton = DrawToolbarPersistedButton(image: scribbleHeavyImage!)
    scribbleHeavyButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleHeavyButton.addTarget(self, action: #selector(scribbleHeavyTapped(sender:)), for: .touchUpInside)
    scribbleHeavyButton.tintColor = .white

    scribblePopoverToolbar.addArrangedSubview(scribbleLightButton)
    scribblePopoverToolbar.addArrangedSubview(scribbleMediumButton)
    scribblePopoverToolbar.addArrangedSubview(scribbleHeavyButton)
    scribblePopoverParent.addSubview(scribblePopoverToolbar)
    scribblePopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = scribblePopoverToolbar.leadingAnchor.constraint(equalTo: scribblePopoverParent.leadingAnchor)
    let top = scribblePopoverToolbar.topAnchor.constraint(equalTo: scribblePopoverParent.topAnchor)
    let trailing = scribblePopoverToolbar.trailingAnchor.constraint(equalTo: scribblePopoverParent.trailingAnchor)
    let bottom = scribblePopoverToolbar.bottomAnchor.constraint(equalTo: scribblePopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = scribblePopoverToolbar.arrangedSubviews[scribblePopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
  }

  @IBAction func eraserButtonTapped(_ sender: UIButton) {
    print("Eraser button tapped")
    clearSecondaryPopovers(except: nil)
  }

  @IBAction func textboxButtonTapped(_ sender: UIButton) {
    print("Textbox button tapped")
  }

  @IBAction func sansSerifButtonTapped(_ sender: UIButton) {
    print("Sans Serif button tapped")
    clearSecondaryPopovers(except: [sansSerifPopoverParent])

    if sansSerifPopoverParent.isDescendant(of: self.view) {
      return
    }

    sansSerifPopoverParent.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 26/255, alpha: 1)
    self.view.addSubview(sansSerifPopoverParent)
    sansSerifPopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = sansSerifPopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = sansSerifPopoverParent.topAnchor.constraint(equalTo: sansSerifButton.topAnchor, constant: 0)
    let widthConstraint = sansSerifPopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = sansSerifPopoverParent.heightAnchor.constraint(equalTo: sansSerifButton.heightAnchor, multiplier: 3)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    sansSerifPopoverToolbar.axis = .vertical
    sansSerifPopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sansSerifPopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    sansSerifPopoverToolbar.addGestureRecognizer(tapGesture)

    // TODO: UPDATE VARIABLE NAMES AND IMAGES

    let scribbleLightImage = UIImage(systemName: "scribble")
    let scribbleLightButton = DrawToolbarPersistedButton(image: scribbleLightImage!)
    scribbleLightButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.tintColor = .white

    let textboxImage = UIImage(systemName: "scribble")
    let textBoxButton = DrawToolbarPersistedButton(image: textboxImage!)
    textBoxButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton.tintColor = .white

    let squareImage = UIImage(systemName: "scribble")
    let squareButton = DrawToolbarPersistedButton(image: squareImage!)
    squareButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton.tintColor = .white

    sansSerifPopoverToolbar.addArrangedSubview(scribbleLightButton)
    sansSerifPopoverToolbar.addArrangedSubview(textBoxButton)
    sansSerifPopoverToolbar.addArrangedSubview(squareButton)
    sansSerifPopoverParent.addSubview(sansSerifPopoverToolbar)
    sansSerifPopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = sansSerifPopoverToolbar.leadingAnchor.constraint(equalTo: sansSerifPopoverParent.leadingAnchor)
    let top = sansSerifPopoverToolbar.topAnchor.constraint(equalTo: sansSerifPopoverParent.topAnchor)
    let trailing = sansSerifPopoverToolbar.trailingAnchor.constraint(equalTo: sansSerifPopoverParent.trailingAnchor)
    let bottom = sansSerifPopoverToolbar.bottomAnchor.constraint(equalTo: sansSerifPopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = sansSerifPopoverToolbar.arrangedSubviews[sansSerifPopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
  }

  @IBAction func stampsButtonTapped(_ sender: UIButton) {
    print("Stamps button tapped")
    clearSecondaryPopovers(except: [stampsPopoverParent])

    if stampsPopoverParent.isDescendant(of: self.view) {
      return
    }

    stampsPopoverParent.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 26/255, alpha: 1)
    self.view.addSubview(stampsPopoverParent)
    stampsPopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = stampsPopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = stampsPopoverParent.topAnchor.constraint(equalTo: leftToolbarParent.topAnchor, constant: 0)
    let widthConstraint = stampsPopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let bottomConstraint = stampsPopoverParent.bottomAnchor.constraint(equalTo: leftToolbarParent.bottomAnchor, constant: 0)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, bottomConstraint])

    stampsPopoverToolbar.axis = .vertical
    stampsPopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(stampsPopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    stampsPopoverToolbar.addGestureRecognizer(tapGesture)

    // TODO: UPDATE VARIABLE NAMES AND IMAGES

    let scribbleLightImage = UIImage(systemName: "scribble")
    let scribbleLightButton = DrawToolbarPersistedButton(image: scribbleLightImage!)
    scribbleLightButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.tintColor = .white

    let textboxImage = UIImage(systemName: "scribble")
    let textBoxButton = DrawToolbarPersistedButton(image: textboxImage!)
    textBoxButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton.tintColor = .white

    let squareImage = UIImage(systemName: "scribble")
    let squareButton = DrawToolbarPersistedButton(image: squareImage!)
    squareButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton.tintColor = .white

    let scribbleLightImage2 = UIImage(systemName: "scribble")
    let scribbleLightButton2 = DrawToolbarPersistedButton(image: scribbleLightImage2!)
    scribbleLightButton2.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton2.tintColor = .white

    let textboxImage2 = UIImage(systemName: "scribble")
    let textBoxButton2 = DrawToolbarPersistedButton(image: textboxImage2!)
    textBoxButton2.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton2.tintColor = .white

    let squareImage2 = UIImage(systemName: "scribble")
    let squareButton2 = DrawToolbarPersistedButton(image: squareImage2!)
    squareButton2.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton2.tintColor = .white

    let scribbleLightImage3 = UIImage(systemName: "scribble")
    let scribbleLightButton3 = DrawToolbarPersistedButton(image: scribbleLightImage3!)
    scribbleLightButton3.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton3.tintColor = .white

    let textboxImage3 = UIImage(systemName: "scribble")
    let textBoxButton3 = DrawToolbarPersistedButton(image: textboxImage3!)
    textBoxButton3.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton3.tintColor = .white

    let squareImage3 = UIImage(systemName: "scribble")
    let squareButton3 = DrawToolbarPersistedButton(image: squareImage3!)
    squareButton3.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton3.tintColor = .white

    let scribbleLightImage4 = UIImage(systemName: "scribble")
    let scribbleLightButton4 = DrawToolbarPersistedButton(image: scribbleLightImage4!)
    scribbleLightButton4.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton4.tintColor = .white

    let textboxImage4 = UIImage(systemName: "scribble")
    let textBoxButton4 = DrawToolbarPersistedButton(image: textboxImage4!)
    textBoxButton4.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton4.tintColor = .white

    let squareImage4 = UIImage(systemName: "scribble")
    let squareButton4 = DrawToolbarPersistedButton(image: squareImage4!)
    squareButton4.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton4.tintColor = .white

    let squareImage5 = UIImage(systemName: "scribble")
    let squareButton5 = DrawToolbarPersistedButton(image: squareImage5!)
    squareButton5.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton5.tintColor = .white

    stampsPopoverToolbar.addArrangedSubview(scribbleLightButton)
    stampsPopoverToolbar.addArrangedSubview(textBoxButton)
    stampsPopoverToolbar.addArrangedSubview(squareButton)
    stampsPopoverToolbar.addArrangedSubview(scribbleLightButton2)
    stampsPopoverToolbar.addArrangedSubview(textBoxButton2)
    stampsPopoverToolbar.addArrangedSubview(squareButton2)
    stampsPopoverToolbar.addArrangedSubview(scribbleLightButton3)
    stampsPopoverToolbar.addArrangedSubview(textBoxButton3)
    stampsPopoverToolbar.addArrangedSubview(squareButton3)
    stampsPopoverToolbar.addArrangedSubview(scribbleLightButton4)
    stampsPopoverToolbar.addArrangedSubview(textBoxButton4)
    stampsPopoverToolbar.addArrangedSubview(squareButton4)
    stampsPopoverToolbar.addArrangedSubview(squareButton5)
    stampsPopoverParent.addSubview(stampsPopoverToolbar)
    stampsPopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = stampsPopoverToolbar.leadingAnchor.constraint(equalTo: stampsPopoverParent.leadingAnchor)
    let top = stampsPopoverToolbar.topAnchor.constraint(equalTo: stampsPopoverParent.topAnchor)
    let trailing = stampsPopoverToolbar.trailingAnchor.constraint(equalTo: stampsPopoverParent.trailingAnchor)
    let bottom = stampsPopoverToolbar.bottomAnchor.constraint(equalTo: stampsPopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = stampsPopoverToolbar.arrangedSubviews[stampsPopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
  }

  @IBAction func opacityButtonTapped(_ sender: UIButton) {
    print("Opacity button tapped")
    clearSecondaryPopovers(except: [opacityPopoverParent])

    if opacityPopoverParent.isDescendant(of: self.view) {
      return
    }

    opacityPopoverParent.backgroundColor = UIColor(red: 22/255, green: 26/255, blue: 26/255, alpha: 1)
    self.view.addSubview(opacityPopoverParent)
    opacityPopoverParent.translatesAutoresizingMaskIntoConstraints = false

    let leadingConstraint = opacityPopoverParent.leadingAnchor.constraint(equalTo: leftToolbarParent.trailingAnchor, constant: 2)
    let topConstraint = opacityPopoverParent.topAnchor.constraint(equalTo: opacityButton.topAnchor, constant: 0)
    let widthConstraint = opacityPopoverParent.widthAnchor.constraint(equalTo: leftToolbarParent.widthAnchor, constant: 0)
    let heightConstraint = opacityPopoverParent.heightAnchor.constraint(equalTo: opacityButton.heightAnchor, multiplier: 4)
    NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])

    opacityPopoverToolbar.axis = .vertical
    opacityPopoverToolbar.distribution = .fillEqually
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(opacityPopoverTapHandler(gesture:)))
    tapGesture.cancelsTouchesInView = false
    opacityPopoverToolbar.addGestureRecognizer(tapGesture)

    // TODO: UPDATE VARIABLE NAMES AND IMAGES

    let scribbleLightImage = UIImage(systemName: "eyedropper")
    let scribbleLightButton = DrawToolbarPersistedButton(image: scribbleLightImage!)
    scribbleLightButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    scribbleLightButton.tintColor = .white

    let textboxImage = UIImage(systemName: "eyedropper")
    let textBoxButton = DrawToolbarPersistedButton(image: textboxImage!)
    textBoxButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    textBoxButton.tintColor = .white

    let squareImage = UIImage(systemName: "eyedropper")
    let squareButton = DrawToolbarPersistedButton(image: squareImage!)
    squareButton.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton.tintColor = .white

    let squareImage2 = UIImage(systemName: "eyedropper")
    let squareButton2 = DrawToolbarPersistedButton(image: squareImage2!)
    squareButton2.addTarget(self, action: #selector(secondaryToolbarButtonTapped(sender:)), for: .touchUpInside)
    squareButton2.tintColor = .white

    opacityPopoverToolbar.addArrangedSubview(scribbleLightButton)
    opacityPopoverToolbar.addArrangedSubview(textBoxButton)
    opacityPopoverToolbar.addArrangedSubview(squareButton)
    opacityPopoverToolbar.addArrangedSubview(squareButton2)
    opacityPopoverParent.addSubview(opacityPopoverToolbar)
    opacityPopoverToolbar.translatesAutoresizingMaskIntoConstraints = false

    let leading = opacityPopoverToolbar.leadingAnchor.constraint(equalTo: opacityPopoverParent.leadingAnchor)
    let top = opacityPopoverToolbar.topAnchor.constraint(equalTo: opacityPopoverParent.topAnchor)
    let trailing = opacityPopoverToolbar.trailingAnchor.constraint(equalTo: opacityPopoverParent.trailingAnchor)
    let bottom = opacityPopoverToolbar.bottomAnchor.constraint(equalTo: opacityPopoverParent.bottomAnchor)
    NSLayoutConstraint.activate([leading, top, trailing, bottom])

    if let selectedButton = opacityPopoverToolbar.arrangedSubviews[opacityPopoverToolbar.savedSelection] as? DrawToolbarPersistedButton {
      selectedButton.select()
    }
  }

  @IBAction func squareButtonTapped(_ sender: UIButton) {
    print("Square button tapped")
    clearSecondaryPopovers(except: nil)
  }

  @IBAction func circleButtonTapped(_ sender: UIButton) {
    print("Circle button tapped")
    clearSecondaryPopovers(except: nil)
  }

  @IBAction func triangleButtonTapped(_ sender: UIButton) {
    print("Triangle button tapped")
    clearSecondaryPopovers(except: nil)
  }


  // MARK: - SECONDARY TOOLBAR TAP HANDLDERS

  @objc func scribbleLightTapped(sender: UIButton) {
    print("Scribble light tapped")
    scribblePopoverToolbar.savedSelection = 0
  }

  @objc func scribbleMediumTapped(sender: UIButton) {
    print("Scribble medium tapped")
    scribblePopoverToolbar.savedSelection = 1
  }

  @objc func scribbleHeavyTapped(sender: UIButton) {
    print("Scribble heavy tapped")
    scribblePopoverToolbar.savedSelection = 2
  }

  // TODO: ADD THE REST OF THE TAP HANDLERS THE SAME WAY THESE WERE ADDED

  // MARK: - UTIL

  private func clearSecondaryPopovers(except: [UIView]?) {
    for view in popoverParents {
      if except != nil {
        if except!.contains(view) {
          continue
        }
      }
      view.removeFromSuperview()
      view.subviews.forEach { subview in
        if let subStackView = subview as? UIStackView {
          subStackView.safelyRemoveArrangedSubviews()
        }
        subview.removeFromSuperview()
      }
    }
  }



}
