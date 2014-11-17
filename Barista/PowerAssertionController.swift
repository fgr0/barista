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
    
    let statusItem: NSStatusItem
    
    
    /*
     * Basic Menu Structure
     */
    
    let menu: NSMenu
    
    let mItemStatus =               NSMenuItem(title: "Barista: Off", action: nil, keyEquivalent: "")
    let mItemToggle =               NSMenuItem(title: "Turn Barista On", action: "toggleMode:", keyEquivalent: "")
    //---
    let mItemAbout =                NSMenuItem(title: "About Barista", action: "showAbout:", keyEquivalent: "")
    //---
    let mItemStartAtLogin =         NSMenuItem(title: "Launch on Login", action: nil, keyEquivalent: "")
    let mItemActivateOnLaunch =     NSMenuItem(title: "Activate on Launch", action: nil, keyEquivalent: "")
    //---
    let mItemAllowDisplaySleep =    NSMenuItem(title: "Allow Display Sleep", action: "toggleDisplaySleep:", keyEquivalent: "")
    //---
    let mItemQuit =                 NSMenuItem(title: "Quit", action: "terminate:", keyEquivalent: "")
    
    /*
     * Init
     */
    override init() {
        // Setup 1st Assertion
        assertion = PowerAssertion(name: "Barista Prevent Sleep", type: .PreventUserIdleSystemSleep, level: .Off)
        if assertion == nil {
            fatalError("Could not create assertion, abort!")
        }

        // Setup Default Menu
        menu = NSMenu(title: "Barista")
        
        // Setup StatusBar Item
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
        statusItem.button?.title = "zZ"
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
        mItemStartAtLogin.hidden = true                 // TODO: Implement 'Launch on Login'
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
        
        // TODO: Find a nicer way to controll the Titles for the MenuItems
        // Maybe possible with Bindings/Transformations?
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

    func toggleDisplaySleep(sender: AnyObject?) {
        if NSUserDefaults.standardUserDefaults().valueForKey("allowDisplaySleep") as Bool {
            assertion?.type = PowerAssertionType.PreventUserIdleDisplaySleep
        } else {
            assertion?.type = PowerAssertionType.PreventUserIdleSystemSleep
        }
    }
}