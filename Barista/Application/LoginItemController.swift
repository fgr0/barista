//
//  LoginItemController.swift
//  Barista
//
//  Created by Franz Greiling on 19.11.14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Cocoa
import ServiceManagement

class LoginItemController: NSObject {
    private var helper: Bundle {
        return Bundle(
            url: Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LoginItems/BaristaHelper.app"))!
    }
    
    @objc var enabled: Bool = false {
        didSet {
            if !SMLoginItemSetEnabled(helper.bundleIdentifier! as CFString, enabled) {
                NSLog("SMLoginItemSetEnabled to \(enabled) for \(helper.bundleIdentifier!) failed")
            }
        }
    }
    
    override init() {
        super.init()
        
        // Register URL with Launch Services
        if LSRegisterURL(self.helper.bundleURL as CFURL, true) != 0 {
            NSLog("LSRegisterURL failed")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Check if app should start at login...
        // ...and bind UserDefaults to the loginItemController to monitor all changes
        self.enabled = UserDefaults.standard.shouldLaunchAtLogin
        UserDefaults.standard.bind(
            NSBindingName(rawValue: UserDefaults.Keys.shouldLaunchAtLogin),
            to: self,
            withKeyPath: "enabled",
            options: nil)
    }
}
