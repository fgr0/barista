//
//  StatusBarMenu.swift
//  Barista
//
//  Created by Franz Greiling on 29.05.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa
import Foundation

class MenuController: NSObject {
    let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    @objc var assertion: PowerAssertion!
    
    // MARK: - UI Outlets
    let statusBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    @IBOutlet var menu: NSMenu!
    
    @IBOutlet weak var stateItem: NSMenuItem!
    @IBOutlet weak var activateItem: NSMenuItem!
    
    @IBOutlet weak var appListItem: NSMenuItem!
    @IBOutlet weak var appListSystem: NSMenuItem!
    @IBOutlet weak var appListSeparator: NSMenuItem!
    
    // MARK: - Setup
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configure Assertion
        let enabled = UserDefaults.standard.bool(forKey: Constants.shouldActivateOnLaunch)
        let allowDisplaySleep = UserDefaults.standard.bool(forKey: Constants.allowDisplaySleep)
        let timeout = 0
        
        self.assertion = PowerAssertion(enabled: enabled, allowDisplaySleep: allowDisplaySleep, timeout: timeout)
        
        UserDefaults.standard.bind(
            NSBindingName(rawValue: Constants.allowDisplaySleep),
            to: self,
            withKeyPath: "assertion.allowDisplaySleep",
            options: nil)
        
        // Setup Status Bar
        self.statusBarItem.button!.title = "zZ"
        self.statusBarItem.button?.appearsDisabled = !assertion.enabled
        self.statusBarItem.menu = menu
    }
    
    func updateAppList() {
//        // Reset Menu Bar 
//        for item in menu.items {
//            if item.tag == 1 {
//                menu.removeItem(item)
//            }
//        }
//        appListItem.isHidden = true
//        appListSeparator.isHidden = true
//        appListSystem.isHidden = true
//        
//        // Show available assertions
//        guard let dict = PowerAssertion.assertionsPreventingSleepByProcess(), dict.count > 0 else {
//            return
//        }
//        
//        appListItem.isHidden = false
//        appListSeparator.isHidden = false
//        
//        let index = menu.index(of: appListSystem)
//        var naughtyApps = Set<NSRunningApplication>()
//        
//        for (pid, list) in dict {
//            if let app = NSRunningApplication(processIdentifier: pid_t(pid)) {
//                naughtyApps.update(with: app)
//                continue
//            }
//
//            for assertion in list {
//                guard let pid = assertion[AssertionDictionaryKey.OnBehalfOfPID],
//                    let app = NSRunningApplication(processIdentifier: pid as! pid_t) else {
//                        appListSystem.isHidden = false
//                        continue
//                }
//                naughtyApps.update(with: app)
//            }
//        }
//        
//        for app in naughtyApps {
//            let appMenuItem = NSMenuItem()
//            appMenuItem.tag = 1
//            appMenuItem.title = app.localizedName!
//            appMenuItem.image = app.icon
//            appMenuItem.image?.size = CGSize(width: 16, height: 16)
//
//            menu.insertItem(appMenuItem, at: index)
//        }
    }

    // MARK: - IB Actions
    @IBAction func setMode(_ sender: NSMenuItem) {
        assertion.enabled = !assertion.enabled
        self.statusBarItem.button?.appearsDisabled = !assertion.enabled
    }
}

// MARK: - NSMenuDelegate Protocol
extension MenuController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu == self.menu else { return }
        
        if assertion.enabled {
            stateItem.title = "\(appName): On"
            activateItem.title = "Turn \(appName) Off"
            statusBarItem.button?.appearsDisabled = false
        } else {
            stateItem.title = "\(appName): Off"
            activateItem.title = "Turn \(appName) On"
            statusBarItem.button?.appearsDisabled = true
        }
    }
}
