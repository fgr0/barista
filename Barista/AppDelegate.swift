//
//  AppDelegate.swift
//  Barista
//
//  Created by Franz Greiling on 28.10.14.
//  Copyright (c) 2018 Franz Greiling. All rights reserved.
//

import Cocoa

// Constants
struct Constants {
    static let notificationTimeoutId    = "barista.notification.timeout"
    static let notificationSleepId      = "barista.notification.sleep"
}


// MARK: -
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var preferenceWindowController: PreferencesWindowController?
    @IBOutlet weak var assertionController: AssertionController!
    
    
    // MARK: - Lifecycle
    override init() {
        super.init()
        
        registerDefaults()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        assertionController.addObserver(self)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.setupLaunchAtLogin()
        NSUserNotificationCenter.default.delegate = self
        
        // Check for first launch
        if !UserDefaults.standard.hadFirstLaunch {
            UserDefaults.standard.hadFirstLaunch = true
            self.showPreferencesWindow(self)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
    
    // MARK: - UserDefaults
    /// Load preference defaults from disk and register them with UserDefaults
    func registerDefaults() {
        guard let plist = Bundle.main.url(forResource: "PreferenceDefaults", withExtension: "plist"),
            let defaults = NSDictionary(contentsOf: plist) as? [String: AnyObject]
            else { NSLog("Unable to load Preference Defaults from Disk!"); return}
        
        UserDefaults.standard.register(defaults: defaults)
        UserDefaults.standard.synchronize()
    }
    
    
    // MARK: - Preference Window
    @IBAction func showPreferencesWindow(_ sender: NSObject) {
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


// MARK: - AssertionObserver
extension AppDelegate: AssertionObserver {
    func assertionTimedOut(after: TimeInterval) {
        guard UserDefaults.standard.sendNotifications else { return }
        
        NSUserNotificationCenter.default.deliveredNotifications.forEach {
            if $0.identifier == Constants.notificationTimeoutId {
                NSUserNotificationCenter.default.removeDeliveredNotification($0)
            }
        }

        let notification = NSUserNotification()
        notification.identifier = Constants.notificationTimeoutId
        notification.title = "Barista turned off"
        notification.informativeText = "Prevented Sleep for " + after.simpleFormat()!
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func assertionStoppedByWake() {
        guard UserDefaults.standard.sendNotifications else { return }
        
        NSUserNotificationCenter.default.deliveredNotifications.forEach {
            if $0.identifier == Constants.notificationSleepId {
                NSUserNotificationCenter.default.removeDeliveredNotification($0)
            }
        }

        let notification = NSUserNotification()
        notification.identifier = Constants.notificationSleepId
        notification.title = "Barista turned off"
        notification.informativeText = "Turned off after system went to sleep"
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}


// MARK: - User Notifications
extension AppDelegate: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        NSUserNotificationCenter.default.removeDeliveredNotification(notification)
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}
