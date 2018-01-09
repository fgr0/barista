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
    static let preventDisplaySleep = "preventDisplaySleep"
    static let defaultTimeout = "defaultTimeout"
    static let alwaysShowApps = "alwaysShowApps"
    static let sendNotifications = "sendNotifications"
    static let endOfDaySelected = "endOfDaySelected"
    
    static let notificationId = "barista.notification"
}


// MARK: -
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var preferenceWindowController: PreferencesWindowController?
    @IBOutlet weak var loginItemController: LoginItemController!
    @IBOutlet weak var powerMgmtController: PowerMgmtController!
    
    
    // MARK: - Lifecycle
    override init() {
        super.init()
        
        registerDefaults()
        NSUserNotificationCenter.default.delegate = self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        powerMgmtController.addObserver(self)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

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


// MARK: - PowerMgmtObserver
extension AppDelegate: PowerMgmtObserver {
    func assertionTimedOut(after: TimeInterval) {
        guard UserDefaults.standard.bool(forKey: Constants.sendNotifications) else { return }

        let notification = NSUserNotification()
        notification.identifier = Constants.notificationId
        notification.title = "Barista turned off"
        notification.subtitle = "Prevented Sleep for " + after.simpleFormat()!
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}


// MARK: - User Notifications
extension AppDelegate: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {

    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        guard notification.identifier == Constants.notificationId else { return }
        
        NSUserNotificationCenter.default.removeDeliveredNotification(notification)
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        guard notification.identifier == Constants.notificationId else { return false }

        return true
    }
}
