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
    static let defaultTimeout = "defaultTimeout"
}

// MARK: -
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var menuController: MenuController!
    @IBOutlet var loginItemController: LoginItemController!
    
    var preferenceWindowController: PreferencesWindowController?
    
    // MARK: - Initalization
    override init() {
        super.init()
        
        registerDefaults()
    }
    
    // MARK: - Launch
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }
    
    // MARK: - Termination
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
    // MARK: - Register UserDefaults
    /// Load preference defaults from disk and register them with UserDefaults
    func registerDefaults() {
        guard let plist = Bundle.main.url(forResource: "PreferenceDefaults", withExtension: "plist"),
            let defaults = NSDictionary(contentsOf: plist) as? [String: AnyObject]
            else { NSLog("Unable to load Preference Defaults from Disk!"); return}
        
        UserDefaults.standard.register(defaults: defaults)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Preference Window
    @IBAction func showPreferencesWindow(_ sender: NSMenuItem) {
        if self.preferenceWindowController == nil {
            self.preferenceWindowController = PreferencesWindowController.defaultController()
        }
        
        guard let prefWindow = self.preferenceWindowController?.window else { return }
        
        prefWindow.delegate = self
        prefWindow.center()
        prefWindow.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Window Delegate Protocol
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow == preferenceWindowController?.window else { return }
        self.preferenceWindowController = nil
    }
}
