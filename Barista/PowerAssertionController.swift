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
    
    var mItemStatus: NSMenuItem
    var mItemToggle: NSMenuItem
    var mItemAbout: NSMenuItem
    var mItemStartAtLogin: NSMenuItem
    var mItemActivateOnLaunch: NSMenuItem
    var mItemQuit:  NSMenuItem
    
    override init() {
        // Setup Assertion
        assertion = PowerAssertion(name: "Barista Prevent Sleep", type: .PreventUserIdleDisplaySleep, level: .Off)
        if assertion == nil {
            fatalError("Could not create assertion, abort!")
        }
        
        
        // Setup Default Menu
        menu = NSMenu(title: "Barista")
        
        mItemStatus = NSMenuItem(title: "Barista: Off", action: nil, keyEquivalent: "")
        menu.addItem(mItemStatus)
        
        mItemToggle = NSMenuItem(title: "Turn Barista On", action: "toggleMode:", keyEquivalent: "")
        menu.addItem(mItemToggle)
        
        menu.addItem(NSMenuItem.separatorItem())
        
        mItemAbout = NSMenuItem(title: "About", action: "orderFrontStandardAboutPanel:", keyEquivalent: "")
        menu.addItem(mItemAbout)
        
        menu.addItem(NSMenuItem.separatorItem())
        
        mItemStartAtLogin = NSMenuItem(title: "Launch on Start", action: "toggleStartAtLogin:", keyEquivalent: "")
        mItemStartAtLogin.state = NSOffState
        menu.addItem(mItemStartAtLogin)
        
        mItemActivateOnLaunch = NSMenuItem(title: "Activate on Launch", action: "toggleActivateOnLaunch:", keyEquivalent: "")
        mItemActivateOnLaunch.state = NSOffState
        menu.addItem(mItemActivateOnLaunch)
        
        menu.addItem(NSMenuItem.separatorItem())
        
        mItemQuit = NSMenuItem(title: "Quit", action: "terminate:", keyEquivalent: "")
        menu.addItem(mItemQuit)
        
        // Setup StatusBar Item
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        statusItem.button?.title = "Barista"
        statusItem.button?.appearsDisabled = true
        statusItem.menu = menu

        super.init()
        
        // Set targets
        menu.delegate = self
        mItemToggle.target = self
        mItemStartAtLogin.target = self
        mItemActivateOnLaunch.target = self

    }
    
    /*
     *  Menu Delegate Methods
     */
    func menuNeedsUpdate(menu: NSMenu) {
        
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
}