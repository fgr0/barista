//
//  PowerAssertionController.swift
//  Barista
//
//  Created by Franz Greiling on 31.10.14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Cocoa

class PowerAssertionController: NSObject, NSMenuDelegate {
    var assertion: PowerAssertion?
    
    var statusItem: NSStatusItem
    
    /*
     * Basic Menu Structure
     */
    var menu: NSMenu
    
    var mItemStatus =               NSMenuItem(title: "Barista: Off", action: nil, keyEquivalent: "")
    var mItemToggle =               NSMenuItem(title: "Turn Barista On", action: "toggleMode:", keyEquivalent: "")
    //---
    var mItemAbout =                NSMenuItem(title: "About", action: "orderFrontStandardAboutPanel:", keyEquivalent: "")
    //---
    var mItemStartAtLogin =         NSMenuItem(title: "Launch on Start", action: nil, keyEquivalent: "")
    var mItemActivateOnLaunch =     NSMenuItem(title: "Activate on Launch", action: nil, keyEquivalent: "")
    //---
    var mItemAllowDisplaySleep =    NSMenuItem(title: "Allow Display Sleep", action: "toggleDisplaySleep:", keyEquivalent: "")
    //---
    var mItemQuit =                 NSMenuItem(title: "Quit", action: "terminate:", keyEquivalent: "")
    
    override init() {
        // Setup 1st Assertion
        assertion = PowerAssertion(name: "Barista Prevent Sleep", type: .PreventUserIdleSystemSleep, level: .Off)
        if assertion == nil {
            fatalError("Could not create assertion, abort!")
        }

        // Setup Default Menu
        menu = NSMenu(title: "Barista")
        
        // Setup StatusBar Item
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        statusItem.button?.title = "Barista"
        statusItem.button?.appearsDisabled = true
        statusItem.menu = menu
        
        super.init()
        
        menu.delegate = self
        
        menu.addItem(mItemStatus)
        menu.addItem(mItemToggle)
        mItemToggle.target = self
        
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(mItemAbout)
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(mItemStartAtLogin)
        mItemStartAtLogin.hidden = true
        menu.addItem(mItemActivateOnLaunch)
        
        let options = [ "NSContinuouslyUpdatesValue" : NSNumber(bool: true) ]
        mItemStartAtLogin.bind(
            "value", toObject: NSUserDefaultsController.sharedUserDefaultsController(),
            withKeyPath: "values.launchOnStart", options: options
        )
        mItemActivateOnLaunch.bind(
            "value", toObject: NSUserDefaultsController.sharedUserDefaultsController(),
            withKeyPath: "values.activateOnLaunch", options: options
        )

        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(mItemAllowDisplaySleep)
        mItemAllowDisplaySleep.target = self
        mItemAllowDisplaySleep.bind(
            "value", toObject: NSUserDefaultsController.sharedUserDefaultsController(),
            withKeyPath: "values.allowDisplaySleep", options: options
        )

        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(mItemQuit)
        
        
        if NSUserDefaults.standardUserDefaults().valueForKey("activateOnLaunch") as Bool {
            toggleMode(self)
        }
    }

    /*
     *  Event Handlers
     */
    func toggleMode(sender: AnyObject?) {
        if assertion?.level == PowerAssertionLevel.On {
            assertion?.level = PowerAssertionLevel.Off
            mItemStatus.title = "Barista: Off"
            mItemToggle.title = "Turn Barista On"
            statusItem.button?.appearsDisabled = true
        } else {
            assertion?.level = PowerAssertionLevel.On
            mItemStatus.title = "Barista: On"
            mItemToggle.title = "Turn Barista Off"
            statusItem.button?.appearsDisabled = false
        }
    }
    
    func toggleStartAtLogin(sender: AnyObject?) {
        mItemStartAtLogin.state = (mItemStartAtLogin.state == NSOnState) ? NSOffState : NSOnState
    }
    
    func toggleActivateOnLaunch(sender: AnyObject?) {
        mItemActivateOnLaunch.state = (mItemActivateOnLaunch.state == NSOnState) ? NSOffState : NSOnState
    }
    
    func toggleDisplaySleep(sender: AnyObject?) {
        if NSUserDefaults.standardUserDefaults().valueForKey("allowDisplaySleep") as Bool {
            assertion?.type = PowerAssertionType.PreventUserIdleDisplaySleep
        } else {
            assertion?.type = PowerAssertionType.PreventUserIdleSystemSleep
        }
    }
}