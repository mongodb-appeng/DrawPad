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

import Foundation
struct Constants {
  // **** Realm Cloud Users:
  // **** Replace MY_INSTANCE_ADDRESS with the hostname of your cloud instance
  // **** e.g., "mycoolapp.us1.cloud.realm.io"
  // ****
  // ****
  // **** ROS On-Premises Users
  // **** Replace the AUTH_URL and REALM_URL strings with the fully qualified versions of
  // **** address of your ROS server, e.g.: "http://127.0.0.1:9080" and "realm://127.0.0.1:9080"
  
  static let MY_INSTANCE_ADDRESS = "reinvent.us1.cloud.realm.io" // <- update this
  
  static let AUTH_URL  = URL(string: "https://\(MY_INSTANCE_ADDRESS)")!
//  static let REALM_URL = URL(string: "realms://\(MY_INSTANCE_ADDRESS)/~/DrawPad")!
  static let REALM_URL = "realms://\(MY_INSTANCE_ADDRESS)/drawings/"
  static let STITCH_APP_ID = "drawpad-owcmq"
  static let S3_BUCKET_NAME = "drawpad-mongodb"
  static let AWS_SERVICE_NAME = "AWS"
  static let ATLAS_SERVICE_NAME = "mongodb-atlas"
  static let REALM_CONFIG_PIN = "27017" // No more tha 5 digits
}

