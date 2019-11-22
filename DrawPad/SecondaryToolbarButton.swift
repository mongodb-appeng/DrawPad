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

class SecondaryToolbarButton: DrawToolbarButton {

  init(image: UIImage) {
    super.init(frame: .zero)
    self.setImage(image, for: .normal)
    self.addTarget(self, action:#selector(onButtonTapped), for: .touchUpInside)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  @objc func onButtonTapped() {
    if self.backgroundColor == self.originalBackgroundColor {
      self.backgroundColor = self.selectedBackgroundColor
    } else {
      self.backgroundColor = self.originalBackgroundColor
    }
  }

}
