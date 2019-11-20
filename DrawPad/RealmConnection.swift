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
  static var realm: Realm? = nil  // Use this realm for objects that **don't** need to be synced to Atlas
  static var realmAtlas: Realm? = nil  // Use this realm for objects that **do** need to be synced to Atlas
  
  static func connect() {
    let config = SyncUser.current?.configuration(realmURL: URL(string: "\(Constants.REALM_URL)\(User.userName)"),
       fullSynchronization: true)
    realm = try! Realm(configuration: config!)
    let configAtlas = SyncUser.current?.configuration(realmURL: URL(string: "\(Constants.REALM_URL_ATLAS)\(User.userName)"),
       fullSynchronization: true)
    realmAtlas = try! Realm(configuration: configAtlas!)
  }
}
