//
//  StatusMenuController.swift
//  GmailAlert
//
//  Created by Ross Tulloch on 18/10/19.
//  Copyright © 2019 Ross Tulloch. All rights reserved.
//

import Foundation
import AppKit
import Combine

class StatusMenuController : NSObject {
    @IBOutlet weak var statusMenu:NSMenu!
    @IBOutlet weak var subjectsMenu:NSMenu!
    private let statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var lastNumberOfUnreadMessages = 0
    private var timer:AnyCancellable?
    private let soundPath = "/System/Library/Sounds/Submarine.aiff"
        
    
    override func awakeFromNib() {
        self.statusBar.menu = self.statusMenu
        self.statusBar.button?.title = MenuTexts.normal

        self.recreateCheckTimer()
        self.checkForMail()
        
        NotificationCenter.default.addObserver(forName: Preferences.DidChangeNotificationName, object: nil, queue: OperationQueue.main ) {_ in
            self.recreateCheckTimer()
        }
    }

}

// MARK:- Check Timer and Mail
extension StatusMenuController {

    private func recreateCheckTimer() {
        
        self.timer = Timer.publish(every: Preferences().checkEveryTimeInSeconds, tolerance: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink() {_ in
                self.checkForMail()
            }
    }
        
    private func checkForMail() {
        let prefs = Preferences()
        GMailNetworking.checkAccount( prefs.account,
                                      password:prefs.password,
                                      onSuccess:updateMenuWithNumberOfMessages,
                                      onError:showError)
    }
    
    private func showError(_ error:NSError ) {
        self.statusBar.button?.title = MenuTexts.error
        self.buildSubjectsMenu([error.localizedDescription])
    }
}

// MARK:- Menu Population
extension StatusMenuController {

    struct MenuTexts {
        static let normal = "✉️"
        static let gotMail = "📩"
        static let error = "✉️👎"
    }

    private func buildSubjectsMenu(_ items:[String] ) {
        while self.subjectsMenu.numberOfItems > 0 {
            self.subjectsMenu.removeItem(at: 0)
        }
        items.forEach {
            self.subjectsMenu.addItem(withTitle: $0, action: nil, keyEquivalent:"")
        }
    }

    private func updateMenuWithNumberOfMessages(_ mailAccountInfo:GMailNetworking.AccountInfo ) {
        guard mailAccountInfo.numberOfUnreadEmails > 0 else {
            self.statusBar.button?.title = MenuTexts.normal
            self.buildSubjectsMenu(["None"])
            return
        }

        self.statusBar.button?.title = "\(MenuTexts.gotMail)\(mailAccountInfo.numberOfUnreadEmails)"
        self.buildSubjectsMenu(mailAccountInfo.UnreadMessagesSubjectLines)

        if mailAccountInfo.numberOfUnreadEmails > self.lastNumberOfUnreadMessages {
            NSSound(contentsOfFile: soundPath, byReference:true)?.play()
        }
        self.lastNumberOfUnreadMessages = mailAccountInfo.numberOfUnreadEmails
        
    }
}

// MARK:- Actions
extension StatusMenuController {

    @IBAction func openMailAction(_ sender: Any?) {
        NSWorkspace.shared.openFile("/System/Applications/Mail.app")
    }

    @IBAction func visitGmailAction(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "http://mail.google.com/")!)
    }

    @IBAction func showPreferences(_ sender: Any?) {
        PreferencesWindowController.show()
    }


}
