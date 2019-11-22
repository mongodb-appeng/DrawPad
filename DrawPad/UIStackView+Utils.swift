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

extension UIStackView {

  func safelyRemoveArrangedSubviews() {

      // Remove all the arranged subviews and save them to an array
      let removedSubviews = arrangedSubviews.reduce([]) { (sum, next) -> [UIView] in
          self.removeArrangedSubview(next)
          return sum + [next]
      }

      // Deactive all constraints at once
      NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))

      // Remove the views from self
      removedSubviews.forEach({ $0.removeFromSuperview() })
  }
  
}
