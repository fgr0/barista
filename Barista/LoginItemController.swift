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
    let mainBundle:     NSBundle
    let helperBundle:   NSBundle
    
    // Controlls the login iteam and UserDefaults
    var enabled: Bool {
        didSet {
            if SMLoginItemSetEnabled(helperBundle.bundleIdentifier!, self.enabled) {
                NSLog("SMLoginItemSetEnabled \(helperBundle.bundlePath) failed")
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
        
        let path: String = (NSURL(fileURLWithPath: mainBundle.bundlePath).URLByAppendingPathComponent(
            "Contents/Library/LoginItems/BaristaHelper.app")?.path)!
        self.helperBundle = NSBundle(path: path)!
        self.enabled = NSUserDefaults.standardUserDefaults().boolForKey("launchOnStart")
        
        super.init()
    }
}
