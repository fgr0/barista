//
//  AppDelegate.swift
//  BaristaHelper
//
//  Created by Franz Greiling on 18.11.2014.
//  Copyright (c) 2018 Franz Greiling. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - NSApplicationDelegate Protocol
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        // Since Helper must reside in Bundle/Contents/Library/LoginItems,
        // so remove unnessesary path elements
        var path = Bundle.main.bundlePath as NSString
        for _ in 1...4 {
            path = path.deletingLastPathComponent as NSString
        }
        
        let mainBundle = Bundle(path: path as String)

        if !NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == mainBundle?.bundleIdentifier } {
            NSWorkspace.shared.launchApplication(path as String)
        }
        
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
