/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import UIKit

enum Pencil {
  case black
  case grey
  case red
  case darkblue
  case lightBlue
  case darkGreen
  case lightGreen
  case brown
  case orange
  case yellow
  case eraser
  
  init?(tag: Int) {
    switch tag {
    case 1:
      self = .black
    case 2:
      self = .grey
    case 3:
      self = .red
    case 4:
      self = .darkblue
    case 5:
      self = .lightBlue
    case 6:
      self = .darkGreen
    case 7:
      self = .lightGreen
    case 8:
      self = .brown
    case 9:
      self = .orange
    case 10:
      self = .yellow
    case 11:
      self = .eraser
    default:
      return nil
    }
  }
  
  var color: UIColor {
    switch self {
    case .black:
      return .black
    case .grey:
      return UIColor(white: 105/255.0, alpha: 1.0)
    case .red:
      return UIColor(red: 1, green: 0, blue: 0, alpha: 1.0)
    case .darkblue:
      return UIColor(red: 0, green: 0, blue: 1, alpha: 1.0)
    case .lightBlue:
      return UIColor(red: 51/255.0, green: 204/255.0, blue: 1, alpha: 1.0)
    case .darkGreen:
      return UIColor(red: 102/255.0, green: 204/255.0, blue: 0, alpha: 1.0)
    case .lightGreen:
      return UIColor(red: 102/255.0, green: 1, blue: 0, alpha: 1.0)
    case .brown:
      return UIColor(red: 160/255.0, green: 82/255.0, blue: 45/255.0, alpha: 1.0)
    case .orange:
      return UIColor(red: 1, green: 102/255.0, blue: 0, alpha: 1.0)
    case .yellow:
      return UIColor(red: 1, green: 1, blue: 0, alpha: 1.0)
    case .eraser:
      return .white
    }
  }
}
