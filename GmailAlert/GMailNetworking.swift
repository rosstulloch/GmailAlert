//
//  GMailNetworking.swift
//  GmailAlert
//
//  Created by Ross Tulloch on 18/10/19.
//  Copyright © 2019 Ross Tulloch. All rights reserved.
//

import Foundation

struct GMailNetworking {
    
    struct Errors {
        static let HTTPErrorDomain = "HTTPError"
        static let GMailNetworkingDomain = "GMailNetworking"
        
        static let NoData = NSError(domain:Errors.GMailNetworkingDomain, code: 1000, userInfo: [NSLocalizedDescriptionKey:"No data!"])
        static let XMLParse = NSError(domain:Errors.GMailNetworkingDomain, code: 1001, userInfo: [NSLocalizedDescriptionKey:"Couldn't parse the XML."])
        static let NoMailCount = NSError(domain:Errors.GMailNetworkingDomain, code: 1002, userInfo: [NSLocalizedDescriptionKey:"Missing mail count in XML."])
    }
    
    struct AccountInfo {
        var numberOfUnreadEmails = 0
        var UnreadMessagesSubjectLines = [String]()
    }

    static func checkAccount(_ account:String,
                        password:String,
                        onSuccess:@escaping (AccountInfo)->Void,
                        onError:@escaping (NSError)->Void )
    {
        var request = URLRequest(url: URL(string: "https://mail.google.com/mail/feed/atom")!)

        let auth = "\(account):\(password)".data(using: .utf8)!.base64EncodedString()
        request.setValue( "Basic \(auth)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    onError(error as NSError)
                    return
                }
                guard let data = data, data.isEmpty == false else {
                    onError(Errors.NoData)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else { return }
                guard httpResponse.statusCode == 200 else {
                    onError(NSError(domain:Errors.HTTPErrorDomain, code: httpResponse.statusCode, userInfo: nil))
                    return
                }
                            
                var results = AccountInfo()
                
                guard let xmlString = String(data: data, encoding: .utf8),
                      let xmlDoc = try? XMLDocument(xmlString: xmlString, options:[]) else {
                        onError(Errors.XMLParse)
                    return
                }
                
                guard let fullcountNodes = try? xmlDoc.nodes(forXPath: "//fullcount"),
                      let fullcount = fullcountNodes.first?.objectValue as? String,
                      let fullcountInt = Int(fullcount) else {
                        onError(Errors.NoMailCount)
                        return
                }
            
                results.numberOfUnreadEmails = fullcountInt
                
                if let nodes = try? xmlDoc.nodes(forXPath: "//title") {
                    results.UnreadMessagesSubjectLines = nodes.compactMap { $0.objectValue as? String }
                    results.UnreadMessagesSubjectLines = results.UnreadMessagesSubjectLines.filter { $0.contains("Gmail - Inbox") == false }
                }
                
                onSuccess(results)
            }
        }.resume()
    }

}
