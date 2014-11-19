//
//  LoginItemController.swift
//  Barista
//
//  Created by Franz Greiling on 19.11.14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Foundation
import ServiceManagement

class LoginItemController: NSObject {
    var mainBundle: NSBundle
    var helperBundle: NSBundle
    
    var enabled = false
    
    // Singleton Implementation
    class var sharedController: LoginItemController {
        struct Static {
            static let instance: LoginItemController = LoginItemController()
        }
        return Static.instance
    }
    
    override init() {
        self.mainBundle = NSBundle.mainBundle()
        
        let path = mainBundle.bundlePath.stringByAppendingPathComponent("Contents/Library/LoginItems/BaristaHelper.app")
        self.helperBundle = NSBundle(path: path)!
        
        super.init()
    }
    
    func launchAtLogin(enabled: Bool) {
        // Try to set LoginItem
        let flag = (enabled ? 1 : 0) as Boolean
        if SMLoginItemSetEnabled(helperBundle.bundleIdentifier, flag) == 0  {
            NSLog("SMLoginItemSetEnabled failed")
        }
    }
}