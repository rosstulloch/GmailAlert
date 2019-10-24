//
//  PreferencesModel.swift
//  GmailAlert
//
//  Created by Ross Tulloch on 18/10/19.
//  Copyright © 2019 Ross Tulloch. All rights reserved.
//

import Foundation

class Preferences : ObservableObject {
    static let DidChangeNotificationName = NSNotification.Name("PreferencesDidChange")
    
    private struct StorageKeys {
        static let Account = "account"
        static let AccountPasswordKey = "accountPassword"
        static let CheckEveryTimeInMinutes = "checkTimeInMinutes"
        static let defaults:[String : Any] = [StorageKeys.Account : "yourgmail@gmail.com",
                                              StorageKeys.CheckEveryTimeInMinutes : 2]
    }

    @Published var account:String = ""
    @Published var password:String = ""
    @Published var checkEveryTimeInMinutes:String = "" {
        // FIXME:- Dumb. This a String because NumberFormatters seem to be broken in SwiftUI (19A602) on macOS.
        didSet {
            guard let value = Int(self.checkEveryTimeInMinutes), value > 0 else {
                self.checkEveryTimeInMinutes = oldValue
                return
            }
        }
    }

    var checkEveryTimeInSeconds:TimeInterval {
        return TimeInterval(UserDefaults.standard.integer(forKey: StorageKeys.CheckEveryTimeInMinutes )*60)
    }

    
    public init() {
        UserDefaults.standard.register(defaults: StorageKeys.defaults)
        
        self.account = UserDefaults.standard.string(forKey: StorageKeys.Account )!
        self.password = KeyChain().load(key: StorageKeys.AccountPasswordKey ) { error in print("\(error)") } ?? ""
        self.checkEveryTimeInMinutes = String(UserDefaults.standard.integer(forKey: StorageKeys.CheckEveryTimeInMinutes ))
    }
    
    public func save() {
        UserDefaults.standard.set( self.account, forKey: StorageKeys.Account)
        UserDefaults.standard.set( self.checkEveryTimeInMinutes, forKey: StorageKeys.CheckEveryTimeInMinutes )

        if KeyChain().load(key: StorageKeys.AccountPasswordKey ) == nil {
            KeyChain().save(key: StorageKeys.AccountPasswordKey, value: self.password) { error in print("\(error)") }
        } else {
            KeyChain().update(key: StorageKeys.AccountPasswordKey, value: self.password) { error in print("\(error)") }
        }
        NotificationCenter.default.post(name: Preferences.DidChangeNotificationName, object: self )
    }
    
    
}
