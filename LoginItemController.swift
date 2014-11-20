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
    let mainBundle: NSBundle
    let helperBundle: NSBundle
    
    var enabled: Bool {
        didSet {
            let flag = (self.enabled ? 1 : 0) as Boolean
            if SMLoginItemSetEnabled(helperBundle.bundleIdentifier, flag) == 0  {
                NSLog("SMLoginItemSetEnabled failed")
            }
            NSUserDefaults.standardUserDefaults().setBool(self.enabled, forKey: "launchOnStart")
        }
    }
    
    // Singleton Implementation
    class var sharedController: LoginItemController {
        struct Static {
            static let instance: LoginItemController = LoginItemController()
        }
        return Static.instance
    }
    
    override init() {
        self.mainBundle = NSBundle.mainBundle()
        
        let path = mainBundle.bundlePath.stringByAppendingPathComponent(
            "Contents/Library/LoginItems/BaristaHelper.app")
        self.helperBundle = NSBundle(path: path)!
        
        self.enabled = NSUserDefaults.standardUserDefaults().boolForKey("launchOnStart")
        
        super.init()
    }
}