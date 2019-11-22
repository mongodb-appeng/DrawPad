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

class DrawToolbarPopoverButton: DrawToolbarPersistedButton {

  private let popoverTriangleMargin: CGFloat = 10
  private let popoverTriangleWidthHeight: CGFloat = 10

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // Draw a triangle in the bottom right area of the button to
  // indicate there are more options associated with this button
  override func draw(_ rect: CGRect) {
    let context = UIGraphicsGetCurrentContext()
    let triangleMaxX = self.bounds.maxX - popoverTriangleMargin
    let triangleMaxY = self.bounds.maxY - popoverTriangleMargin
    let triangleMinX = triangleMaxX - popoverTriangleWidthHeight
    let triangleMinY = triangleMaxY - popoverTriangleWidthHeight
    context?.beginPath()
    context?.move(to: CGPoint(x: triangleMaxX, y: triangleMinY))
    context?.addLine(to: CGPoint(x: triangleMaxX, y: triangleMaxY))
    context?.addLine(to: CGPoint(x: triangleMinX, y: triangleMaxY))
    context?.closePath()
    context?.setFillColor(UIColor.white.cgColor)
    context?.fillPath()
  }

}
