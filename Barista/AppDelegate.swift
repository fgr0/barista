//
//  AppDelegate.swift
//  Barista
//
//  Created by Franz Greiling on 28/10/14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Cocoa

// Constants
struct Constants {
    static let shouldActivateOnLaunch = "shouldActivateOnLaunch"
    static let shouldLaunchAtLogin = "shouldLaunchAtLogin"
    static let allowDisplaySleep = "allowDisplaySleep"
    
}

let prefDefaults: [String: AnyObject] = [
    Constants.shouldActivateOnLaunch :  NSNumber(value: true),
    Constants.shouldLaunchAtLogin :     NSNumber(value: true),
    Constants.allowDisplaySleep :       NSNumber(value: false)
]


// MARK: -
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var menuController: MenuController!
    @IBOutlet var loginItemController: LoginItemController!
    
    // MARK: - Init
    override init() {
        // Setup default values for preferences
        UserDefaults.standard.register(defaults: prefDefaults)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - NSApplicationDelegate Protocol
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
}
