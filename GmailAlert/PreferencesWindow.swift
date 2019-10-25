//
//  ContentView.swift
//  GmailAlert
//
//  Created by Ross Tulloch on 15/10/19.
//  Copyright © 2019 Ross Tulloch. All rights reserved.
//

import SwiftUI

class PreferencesWindowController : NSWindowController, NSWindowDelegate {
    static var preferencesWindowController:PreferencesWindowController?
    
    
    static func show() {
        NSApp.activate(ignoringOtherApps: true)
        
        guard preferencesWindowController == nil else {
            preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        let preferencesWindow = NSWindow( contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                                          styleMask: [.titled, .fullSizeContentView, .resizable],
                                          backing: .buffered, defer: false)
        preferencesWindowController = PreferencesWindowController(window: preferencesWindow)

        preferencesWindow.center()
        preferencesWindow.setFrameAutosaveName("Preferences")
        preferencesWindow.contentView = NSHostingView(rootView: PreferencesContent(preferencesData:Preferences(), ownerWindowController: preferencesWindowController ))
        preferencesWindow.center()
        preferencesWindow.makeKeyAndOrderFront(nil)
        preferencesWindow.delegate = preferencesWindowController
    }

    func windowWillClose(_ notification: Notification) {
        PreferencesWindowController.preferencesWindowController = nil
    }
    
}

struct PreferencesContent: View {
    @ObservedObject var preferencesData: Preferences
    let ownerWindowController: PreferencesWindowController?
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: CGFloat(12.0)) {
                    Text("Account:")
                    Text("Password:")
                    Text("Check Every:")
                }.padding()
                
                VStack(alignment: .leading) {
                    TextField( "your email address@gmail.com", text:self.$preferencesData.account )
                    SecureField( "your password", text:self.$preferencesData.password )
                    HStack {
                        TextField( "minutes", text:self.$preferencesData.checkEveryTimeInMinutes)
                            .frame(width: 50)
                        Text("minutes")
                    }
                }.padding()
            }

            VStack(alignment: .trailing) {
                HStack() {
                    Spacer()
                    // FIXME:- Text button sizes seem to be broken (19A602) so add padding. Bug or Feature?
                    Button(action:{
                        self.ownerWindowController?.close()
                    }) {
                        Text("Cancel")
                        .padding()
                        // FIXME:- Text Button height is always wrong. (19A602)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 0))
                    }
                    Button(action:{
                        self.ownerWindowController?.close()
                        self.preferencesData.save()
                    }) {
                        Text("OK")
                        .padding()
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 0))
                    }
                }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 15))
            }
        }


    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        return PreferencesContent(preferencesData:Preferences(), ownerWindowController: nil)
    }
}
