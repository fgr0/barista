//
//  AppDelegate.swift
//  Barista
//
//  Created by Franz Greiling on 28/10/14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var controller: PowerAssertionController?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        // register User Defaults
        let defaults: Dictionary<String,AnyObject> = [
            "activateOnLaunch" : NSNumber(bool: false),
            "launchOnStart" : NSNumber(bool: false),
            "allowDisplaySleep" : NSNumber(bool: true)
        ]
        NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
        
        // load Controller
        controller = PowerAssertionController()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func showAbout(sender: AnyObject) {
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        NSApplication.sharedApplication().orderFrontStandardAboutPanel(sender)
    }

}

