//
//  AppDelegate.swift
//  BaristaHelper
//
//  Created by Franz Greiling on 18.11.2014.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - NSApplicationDelegate Protocol
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        // Since Helper must reside in Bundle/Contents/Library/LoginItems
        // remove unnessesary path elements
        let appPath = ((((NSURL(fileURLWithPath: Bundle.main.bundlePath) as NSURL)
            .deletingLastPathComponent as NSURL?)?.deletingLastPathComponent as NSURL?)?
            .deletingLastPathComponent?.deletingLastPathComponent().path)!
        let appBundle = Bundle(path: appPath)
        var isRunning = false
        
        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == appBundle?.bundleIdentifier {
                isRunning = true
                break
            }
        }

        if !isRunning {
            NSWorkspace.shared.launchApplication(appPath)
        }
        
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
