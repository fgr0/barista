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
    private let helper: Bundle
    
    @objc dynamic var enabled: Bool = false {
        didSet {
            if !SMLoginItemSetEnabled(helper.bundleIdentifier! as CFString, enabled) {
                NSLog("SMLoginItemSetEnabled to \(enabled) for \(helper.bundleIdentifier!) failed")
            }
        }
    }
    
    override init() {
        let url = URL(fileURLWithPath: Bundle.main.bundlePath)
            .appendingPathComponent("Contents/Library/LoginItems/BaristaHelper.app")
        
        self.helper = Bundle(path: url.path)!
        
        super.init()
        
        // Register URL with Launch Services
        if LSRegisterURL(url as CFURL, true) != 0 {
            NSLog("LSRegisterURL failed")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Check if app should start at login...
        // ...and bind UserDefaults to the loginItemController to monitor all changes
        self.enabled = UserDefaults.standard.bool(forKey: Constants.shouldLaunchAtLogin)
        UserDefaults.standard.bind(
            NSBindingName(rawValue: Constants.shouldLaunchAtLogin),
            to: self,
            withKeyPath: "enabled",
            options: nil)
    }
}
