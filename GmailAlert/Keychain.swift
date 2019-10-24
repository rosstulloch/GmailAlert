//
//  Keychain.swift
//  ProFind
//
//  Created by Ross Tulloch on 18/1/19.
//  Copyright © 2019 Ross Tulloch. All rights reserved.
//

import Foundation
import Security

///////////////////////////////////////////////////
// Inspiration from https://stackoverflow.com/a/37539998/1694526
///////////////////////////////////////////////////


struct KeyChain {
    
    public func save(key: String, value: String, onError:((NSError)->Void)? = nil ){
        guard let data  = value.data(using: .utf8) else { onError?(NSError(domain: kCFErrorDomainOSStatus as String, code: -1, userInfo: nil)); return }
        
        let query:[String : Any] = [ kSecClass as String       : kSecClassGenericPassword as String,
                                     kSecAttrAccount as String : key,
                                     kSecValueData as String   : data ]

        let errorCode = SecItemAdd(query as CFDictionary, nil)
        onError?(secError(errorCode))
    }
    
    public func load(key: String, onError:((NSError)->Void)? = nil ) -> String? {
            let query:[String:Any] = [  kSecClass as String       : kSecClassGenericPassword,
                                        kSecAttrAccount as String : key,
                                        kSecReturnData as String  : kCFBooleanTrue!,
                                        kSecMatchLimit as String  : kSecMatchLimitOne ]

        var dataTypeRef: AnyObject? = nil
        let errorCode = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard errorCode == errSecSuccess else {
            onError?(secError(errorCode))
            return nil
        }
        
        return String(data: dataTypeRef as! Data, encoding: .utf8)
    }
    
    public func update(key: String, value: String, onError:((NSError)->Void)? = nil ) {
        guard let data  = value.data(using: .utf8) else { onError?(NSError(domain: kCFErrorDomainOSStatus as String, code: -1, userInfo: nil)); return }
        
        let query:[String:Any] = [kSecClass as String : kSecClassGenericPassword as String,
                                  kSecAttrAccount as String : key]

        let errorCode = SecItemUpdate(query as CFDictionary, [kSecValueData as String:data] as CFDictionary)
        guard errorCode == errSecSuccess else {
            onError?(secError(errorCode))
            return
        }
    }
    
    private func secError(_ errorCode:OSStatus) -> NSError {
        if let errorString = SecCopyErrorMessageString( errorCode, nil) {
            return NSError(domain: kCFErrorDomainOSStatus as String, code: Int(errorCode), userInfo: [NSLocalizedFailureReasonErrorKey:errorString])
        } else {
            return NSError(domain: kCFErrorDomainOSStatus as String, code: Int(errorCode), userInfo: nil)
        }
    }
    
}

