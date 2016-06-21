//
//  AppDelegate.swift
//  Barista
//
//  Created by Franz Greiling on 28/10/14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Cocoa

let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as! String

enum Settings: String {
    case activateOnLaunch = "activateOnLaunch"
    case launchOnStart = "launchOnStart"
    case allowDisplaySleep = "allowDisplaySleep"
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var menu: NSMenu!
    @IBOutlet var displaySleepItem: NSMenuItem!
    @IBOutlet var activeItem: NSMenuItem!
    @IBOutlet var toggleItem: NSMenuItem!
    @IBOutlet var loginItem: NSMenuItem!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
    var assertion: PowerAssertion?

    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // register user defaults
        let defaults: Dictionary<String,AnyObject> = [
            Settings.activateOnLaunch.rawValue : NSNumber(bool: false),
            Settings.launchOnStart.rawValue : NSNumber(bool: false),
            Settings.allowDisplaySleep.rawValue : NSNumber(bool: true)
        ]
        NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
        
        // Setup assertion
        let starttype: PowerAssertionType = NSUserDefaults.standardUserDefaults()
            .valueForKey(Settings.allowDisplaySleep.rawValue) as! Bool ?
                .PreventUserIdleSystemSleep : .PreventUserIdleDisplaySleep
        
        assertion = PowerAssertion(name: NSBundle.mainBundle().bundleIdentifier!, type: starttype, level: .On)
        if assertion == nil {
            fatalError("Could not create assertion, abort!")
        }
        
        // Setup StatusBar Item
        statusItem.button?.title = "zZ"
        statusItem.button?.appearsDisabled = true
        statusItem.menu = menu
        
        // Setup Target-Actions
        displaySleepItem.target = self
        displaySleepItem.action = #selector(AppDelegate.toggleDisplaySleep(_:))
        displaySleepItem.bind(
            "value", toObject: NSUserDefaultsController.sharedUserDefaultsController(),
            withKeyPath: "values.allowDisplaySleep", options: [ "NSContinuouslyUpdatesValue" : NSNumber(bool: true) ]
        )
        
        toggleItem.target = self
        toggleItem.action = #selector(AppDelegate.toggleMode(_:))
        
        loginItem.bind(
            "value", toObject: LoginItemController.sharedController(),
            withKeyPath: "enabled", options: [ "NSContinuouslyUpdatesValue" : NSNumber(bool: true) ]
        )
        
        // TODO: Find a nicer way to controll the Titles for the MenuItems
        // Maybe possible with Bindings/Transformations?
        setMode(NSUserDefaults.standardUserDefaults().valueForKey("activateOnLaunch") as! Bool ? .On : .Off)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func setMode(mode: PowerAssertionLevel) {
        switch mode {
        case .On:
            assertion?.level = .On
            activeItem.title = "\(appName): On"
            toggleItem.title = "Turn \(appName) Off"
            statusItem.button?.appearsDisabled = false
        case .Off:
            assertion?.level = .Off
            activeItem.title = "\(appName): Off"
            toggleItem.title = "Turn \(appName) On"
            statusItem.button?.appearsDisabled = true
        }
    }
    
    func toggleMode(sender: AnyObject) {
        if assertion?.level == PowerAssertionLevel.On {
            setMode(.Off)
        } else {
            setMode(.On)
        }
    }

    func toggleDisplaySleep(sender: AnyObject) {
        if assertion?.type == PowerAssertionType.PreventUserIdleSystemSleep {
            assertion?.type = PowerAssertionType.PreventUserIdleDisplaySleep
        } else {
            assertion?.type = PowerAssertionType.PreventUserIdleSystemSleep
        }
    }
}
