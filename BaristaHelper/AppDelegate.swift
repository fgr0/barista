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

    func applicationWillFinishLaunching(aNotification: NSNotification) {
        // Since Helper must reside in Bundle/Contents/Library/LoginItems
        // remove unnessesary path elements
        let appPath = (NSURL(fileURLWithPath: NSBundle.mainBundle().bundlePath)
            .URLByDeletingLastPathComponent?.URLByDeletingLastPathComponent?
            .URLByDeletingLastPathComponent?.URLByDeletingLastPathComponent!.path)!
        let appBundle = NSBundle(path: appPath)
        var isRunning = false
        
        for app in NSWorkspace.sharedWorkspace().runningApplications {
            if app.bundleIdentifier == appBundle?.bundleIdentifier {
                isRunning = true
                break
            }
        }

        if !isRunning {
            NSWorkspace.sharedWorkspace().launchApplication(appPath)
        }
        
        NSApplication.sharedApplication().terminate(nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

