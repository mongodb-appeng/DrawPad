//
//  RealmConnection.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import Foundation
import RealmSwift

class RealmConnection {
  static var realm: Realm? = nil
  
  static func connect() {
    let config = SyncUser.current?.configuration(realmURL: URL(string: "\(Constants.REALM_URL)\(User.userName)"),
       fullSynchronization: true)
    realm = try! Realm(configuration: config!)
  }
}
