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

import RealmSwift
import UIKit

class StoredImage: Object {
  @objc dynamic var itemId: String = UUID().uuidString
  @objc dynamic var email: String = ""
  @objc dynamic var image: Data? = nil
  @objc dynamic var imageLink: String? = nil
  @objc dynamic var timestamp = Date()
  
  convenience init(image: Data?, name email: String) {
    self.init()
    self.email = email
    self.image = image
  }
  
  override static func primaryKey() -> String? {
      return "itemId"
  }
}
