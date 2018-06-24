//
//  AppDelegate+LoginItem.swift
//  Barista
//
//  Created by Franz Greiling on 19.11.14.
//  Copyright (c) 2018 Franz Greiling. All rights reserved.
//

import Cocoa
import ServiceManagement

extension AppDelegate {
    fileprivate static let helper = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LoginItems/BaristaLaunchHelper.app"))!
    
    @objc dynamic var launchAtLogin: Bool {
        get {
            return UserDefaults.standard.shouldLaunchAtLogin
        }
        set(enabled) {
            self.willChangeValue(forKey: "launchAtLogin")
            if SMLoginItemSetEnabled(AppDelegate.helper.bundleIdentifier! as CFString, enabled) {
                UserDefaults.standard.shouldLaunchAtLogin = enabled
            }
            self.didChangeValue(forKey: "launchAtLogin")
        }
    }
    
    func setupLaunchAtLogin() {
        if LSRegisterURL(AppDelegate.helper.bundleURL as CFURL, true) != 0 {
            // error handling
        }
        
        self.launchAtLogin = UserDefaults.standard.shouldLaunchAtLogin
    }
}
